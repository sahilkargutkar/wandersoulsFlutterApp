import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wonder_souls/src/features/trips/presentation/screens/list_article.dart';
import 'package:wonder_souls/src/features/trips/presentation/screens/list_destination.dart';
import 'package:wonder_souls/src/features/trips/presentation/screens/destination_details.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wonder_souls/src/features/trips/presentation/cubit/blogs_cubit.dart';

import 'package:wonder_souls/src/config/core/injector/injector.dart';
import 'package:wonder_souls/src/config/core/model/place_model.dart';
import 'package:wonder_souls/src/config/core/services/api_services.dart';

import 'package:wonder_souls/src/config/utils/common_widgets/app_search_bar.dart';
import 'package:wonder_souls/src/config/utils/common_widgets/article_card.dart';
import 'package:wonder_souls/src/config/utils/common_widgets/destination_card.dart';
import 'package:wonder_souls/src/config/utils/common_widgets/size.dart';
import 'package:wonder_souls/src/config/utils/common_widgets/staggered_fade_slide.dart';

import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_text.dart';

import 'package:wonder_souls/src/features/home/presentation/screens/search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService service = sl<ApiService>();

  List<PlaceModel> destinations = [];
  bool isLoading = true;
  String? _destinationsError;

  @override
  void initState() {
    super.initState();
    fetchPopularDestinations();
  }

  Future<void> fetchPopularDestinations() async {
    setState(() {
      isLoading = true;
      _destinationsError = null;
    });

    final result = await service.getLocations(1, 5, "");
    if (!mounted) return;

    result.fold(
      (failure) {
        debugPrint("fetchPopularDestinations failure: ${failure.message}");

        setState(() {
          _destinationsError = failure.message;
          isLoading = false;
        });
      },

      (success) {
        setState(() {
          destinations = success;
          _destinationsError = null;
          isLoading = false;
        });
      },
    );
  }

  Widget _buildSearchBar() {
    return AppSearchBar(
      hintText: 'Where to next?',
      onTap: () {
        context.push(SearchScreen.routeName);
      },
      trailing: Container(
        padding: EdgeInsets.only(left: 6.w, right: 6.w),
        decoration: BoxDecoration(
          color: context.primaryTint,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required VoidCallback onViewAll,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: context.text.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 20.sp,
            letterSpacing: -0.5,
          ),
        ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onViewAll,
            borderRadius: BorderRadius.circular(20.r),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: context.primaryTint,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Row(
                children: [
                  Text(
                    'See All',
                    style: context.primaryLabel?.copyWith(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  4.w.width,
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: context.primary,
                    size: 16.sp,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoader() {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth < 360 ? screenWidth * 0.44 : 180.w;

    return SizedBox(
      height: 270.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        padding: EdgeInsets.only(right: 4.w),
        separatorBuilder: (_, __) => 14.w.width,
        itemBuilder: (context, index) {
          return Container(
            width: cardWidth,
            decoration: BoxDecoration(
              color: context.shimmerBase,
              borderRadius: BorderRadius.circular(20.r),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPopularDestinations() {
    if (isLoading) {
      return _buildLoader();
    }

    if (destinations.isEmpty) {
      return SizedBox(
        height: 220.h,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.travel_explore_rounded,
                size: 48.sp,
                color: context.onSurfaceVariant.withAlpha(80),
              ),
              SizedBox(height: 12.h),
              Text(
                _destinationsError ?? "No destinations found",
                style: context.text.bodyLarge?.copyWith(
                  color: context.onSurfaceVariant,
                ),
              ),
              if (_destinationsError != null) ...[
                SizedBox(height: 8.h),
                TextButton(
                  onPressed: fetchPopularDestinations,
                  child: const Text("Retry"),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;

    /// RESPONSIVE CARD WIDTH — show 2 cards side by side with peek
    final cardWidth = screenWidth < 360
        ? screenWidth * 0.44
        : screenWidth < 400
        ? screenWidth * 0.44
        : screenWidth < 600
        ? screenWidth * 0.64
        : 180.w;

    /// RESPONSIVE HEIGHT
    final sectionHeight = screenWidth < 360
        ? 220.h
        : screenWidth < 400
        ? 235.h
        : screenWidth < 600
        ? 250.h
        : 270.h;

    return SizedBox(
      height: sectionHeight,

      child: ListView.separated(
        scrollDirection: Axis.horizontal,

        itemCount: destinations.length,

        padding: EdgeInsets.only(left: 0, right: 4.w),

        separatorBuilder: (_, __) => 14.w.width,

        itemBuilder: (context, index) {
          final destination = destinations[index];

          return StaggeredFadeSlide(
            index: index,
            child: SizedBox(
              width: cardWidth,
              child: InkWell(
                borderRadius: BorderRadius.circular(20.r),
                onTap: () {
                  context.push(
                    DestinationDetailsScreen.routeName,
                    extra: destination,
                  );
                },
                child: DestinationCard(
                  imageUrl:
                      "https://images.unsplash.com/photo-1545569341-9eb8b30979d9?q=80&w=1200",
                  city: destination.name,
                  country: destination.address,
                  flagEmoji: "📍",
                  cardWidth: cardWidth,
                  place: destination,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPopularArticles() {
    return BlocBuilder<BlogsCubit, BlogsState>(
      builder: (context, state) {
        if (state is BlogsLoading) {
          return SizedBox(
            height: 120.h,
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (state is BlogsError) {
          return SizedBox(
            height: 50.h,
            child: Center(
              child: Text(
                state.message,
                textAlign: TextAlign.center,
                style: context.text.bodySmall,
              ),
            ),
          );
        }

        if (state is BlogsLoaded) {
          final blogs = state.blogs;
          if (blogs.isEmpty) {
            return SizedBox(
              height: 50.h,
              child: const Center(child: Text("No articles found")),
            );
          }

          final screenWidth = MediaQuery.of(context).size.width;
          final articleHeight = screenWidth < 360
              ? 230.h
              : screenWidth < 400
                  ? 240.h
                  : 260.h;

          return SizedBox(
            height: articleHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: blogs.length,
              separatorBuilder: (_, __) => 16.w.width,
              itemBuilder: (context, index) {
                final blog = blogs[index];

                return StaggeredFadeSlide(
                  index: index,
                  child: InkWell(
                    onTap: () {
                      context.push('/BlogDetail', extra: blog);
                    },
                    borderRadius: BorderRadius.circular(16.r),
                    child: ArticleCard(
                      imageUrl: blog.image,
                      title: blog.title,
                      date: _formatDate(blog.createdAt),
                      readTime: blog.readTime,
                    ),
                  ),
                );
              },
            ),
          );
        }

        return const SizedBox.shrink();
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

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: context.primary,

      onRefresh: () async {
        await fetchPopularDestinations();
        if (mounted) {
          context.read<BlogsCubit>().fetchBlogs();
        }
      },

      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),

        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              /// SEARCH BAR — now using consistent AppSearchBar
              _buildSearchBar(),

              24.h.height,

              /// DESTINATION HEADER
              _buildSectionHeader(
                title: 'Popular Destinations',

                onViewAll: () {
                  context.push(ListDestination.routeName);
                },
              ),

              14.h.height,

              /// DESTINATIONS
              _buildPopularDestinations(),

              24.h.height,

              /// ARTICLE HEADER
              _buildSectionHeader(
                title: 'Popular Articles',

                onViewAll: () {
                  context.push(ListArticle.routeName);
                },
              ),

              14.h.height,

              /// ARTICLES
              _buildPopularArticles(),

              20.h.height,
            ],
          ),
        ),
      ),
    );
  }
}
