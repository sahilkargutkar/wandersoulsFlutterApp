import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wonder_souls/src/config/core/model/place_model.dart';
import 'package:wonder_souls/src/features/trips/presentation/cubit/saved_places_cubit.dart';
import 'package:wonder_souls/src/features/trips/presentation/cubit/blogs_cubit.dart';
import 'package:wonder_souls/src/features/trips/model/blog_model.dart';
import 'package:wonder_souls/src/features/trips/presentation/widgets/empty_saved_card.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_text.dart';
import 'package:wonder_souls/src/config/utils/common_widgets/article_card.dart';
import 'package:go_router/go_router.dart';
import '../widgets/destination_card_list.dart';

class SavedTripsScreen extends StatefulWidget {
  final ValueNotifier<String>? searchNotifier;

  const SavedTripsScreen({super.key, this.searchNotifier});

  @override
  State<SavedTripsScreen> createState() => _SavedTripsScreenState();
}

class _SavedTripsScreenState extends State<SavedTripsScreen> {
  int _selectedTab = 0; // 0: Blogs, 1: Places

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab Selector Row
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: context.mutedBackground,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton(
                    index: 0,
                    title: "Travel Blogs",
                    icon: Icons.article_rounded,
                  ),
                ),
                Expanded(
                  child: _buildTabButton(
                    index: 1,
                    title: "Saved Places",
                    icon: Icons.bookmark_rounded,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Body Content
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: widget.searchNotifier != null
                ? ValueListenableBuilder<String>(
                    key: ValueKey(_selectedTab),
                    valueListenable: widget.searchNotifier!,
                    builder: (context, query, child) {
                      return _selectedTab == 0
                          ? _buildBlogsSection(context, query)
                          : _buildSavedPlacesSection(context, query);
                    },
                  )
                : (_selectedTab == 0
                    ? _buildBlogsSection(context, "")
                    : _buildSavedPlacesSection(context, "")),
          ),
        ),
      ],
    );
  }

  Widget _buildTabButton({
    required int index,
    required String title,
    required IconData icon,
  }) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? context.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(8.r),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withAlpha(8),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16.sp,
              color: isSelected ? context.primary : context.onSurfaceVariant,
            ),
            SizedBox(width: 6.w),
            Text(
              title,
              style: context.text.labelMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? context.primary : context.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedPlacesSection(BuildContext context, String query) {
    return BlocBuilder<SavedPlacesCubit, List<PlaceModel>>(
      builder: (context, savedPlaces) {
        if (savedPlaces.isEmpty) {
          return const EmptySavedCard();
        }

        final filteredPlaces = query.isEmpty
            ? savedPlaces
            : savedPlaces.where((place) {
                final nameMatch =
                    place.name.toLowerCase().contains(query.toLowerCase());
                final addrMatch =
                    place.address.toLowerCase().contains(query.toLowerCase());
                return nameMatch || addrMatch;
              }).toList();

        if (filteredPlaces.isEmpty) {
          return Center(
            child: Text(
              "No matching saved places",
              style: context.text.bodyMedium?.copyWith(
                color: context.onSurfaceVariant,
              ),
            ),
          );
        }

        return _buildPlaceList(context, filteredPlaces);
      },
    );
  }

  Widget _buildBlogsSection(BuildContext context, String query) {
    return BlocBuilder<BlogsCubit, BlogsState>(
      builder: (context, state) {
        if (state is BlogsLoading) {
          return Center(
            child: CircularProgressIndicator(color: context.primary),
          );
        }

        if (state is BlogsError) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    color: Colors.redAccent,
                    size: 48.sp,
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: context.text.bodyMedium,
                  ),
                  SizedBox(height: 16.h),
                  ElevatedButton(
                    onPressed: () {
                      context.read<BlogsCubit>().fetchBlogs();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.primary,
                      foregroundColor: context.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: const Text("Retry"),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is BlogsLoaded) {
          final blogs = state.blogs;
          if (blogs.isEmpty) {
            return Center(
              child: Text(
                "No blogs available",
                style: context.text.bodyMedium?.copyWith(
                  color: context.onSurfaceVariant,
                ),
              ),
            );
          }

          final filteredBlogs = query.isEmpty
              ? blogs
              : blogs.where((blog) {
                  final titleMatch =
                      blog.title.toLowerCase().contains(query.toLowerCase());
                  final descMatch =
                      blog.desc.toLowerCase().contains(query.toLowerCase());
                  final categoryMatch =
                      blog.category.toLowerCase().contains(query.toLowerCase());
                  final authorMatch =
                      blog.author.toLowerCase().contains(query.toLowerCase());
                  return titleMatch ||
                      descMatch ||
                      categoryMatch ||
                      authorMatch;
                }).toList();

          if (filteredBlogs.isEmpty) {
            return Center(
              child: Text(
                "No matching blogs",
                style: context.text.bodyMedium?.copyWith(
                  color: context.onSurfaceVariant,
                ),
              ),
            );
          }

          return _buildBlogsList(context, filteredBlogs);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildPlaceList(BuildContext context, List<PlaceModel> places) {
    return ListView.builder(
      padding: EdgeInsets.only(
        left: 16.w,
        right: 16.w,
        top: 8.h,
        bottom: 88.h,
      ),
      itemCount: places.length,
      itemBuilder: (_, index) {
        final place = places[index];
        return Padding(
          padding: EdgeInsets.only(bottom: 16.h),
          child: DestinationCardList(
            imageUrl:
                place.googleMapsUrl ??
                "https://images.unsplash.com/photo-1545569341-9eb8b30979d9?q=80&w=1200",
            city: place.name,
            country: place.address,
            flagEmoji: "📍",
            place: place,
          ),
        );
      },
    );
  }

  Widget _buildBlogsList(BuildContext context, List<BlogModel> blogs) {
    return ListView.builder(
      padding: EdgeInsets.only(
        left: 16.w,
        right: 16.w,
        top: 8.h,
        bottom: 88.h,
      ),
      itemCount: blogs.length,
      itemBuilder: (_, index) {
        final blog = blogs[index];
        return Padding(
          padding: EdgeInsets.only(bottom: 24.h),
          child: InkWell(
            onTap: () {
              context.push('/BlogDetail', extra: blog);
            },
            borderRadius: BorderRadius.circular(16.r),
            child: ArticleCard(
              imageUrl: blog.image,
              title: blog.title,
              date: _formatDate(blog.createdAt),
              ratio: 16 / 9,
              cardWidth: MediaQuery.of(context).size.width - 32.w,
              readTime: blog.readTime,
            ),
          ),
        );
      },
    );
  }

  String _formatDate(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString);
      final months = [
        "Jan",
        "Feb",
        "Mar",
        "Apr",
        "May",
        "Jun",
        "Jul",
        "Aug",
        "Sep",
        "Oct",
        "Nov",
        "Dec"
      ];
      return "${dateTime.day} ${months[dateTime.month - 1]}, ${dateTime.year}";
    } catch (e) {
      return isoString;
    }
  }
}
