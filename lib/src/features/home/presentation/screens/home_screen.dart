import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:wonder_souls/src/config/core/injector/injector.dart';
import 'package:wonder_souls/src/config/core/model/place_model.dart';
import 'package:wonder_souls/src/config/core/services/api_services.dart';
import 'package:wonder_souls/src/config/model/success.dart';
import 'package:wonder_souls/src/config/utils/api_constant.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';
import 'package:wonder_souls/src/config/utils/trip_image_helper.dart';
import 'package:wonder_souls/src/features/auth/data/datasource/auth_local_data_source.dart';
import 'package:wonder_souls/src/features/home/presentation/screens/search_screen.dart';
import 'package:wonder_souls/src/features/home/presentation/widgets/ai_itinerary_banner.dart';
import 'package:wonder_souls/src/features/trips/model/public_trips_data.dart';
import 'package:wonder_souls/src/features/trips/model/trip.dart';
import 'package:wonder_souls/src/features/trips/presentation/screens/destination_details.dart';
import 'package:wonder_souls/src/features/trips/presentation/screens/list_destination.dart';
import 'package:wonder_souls/src/features/trips/presentation/screens/list_public_trips.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wonder_souls/src/config/utils/app_toast.dart';
import 'package:wonder_souls/src/features/trips/model/blog_model.dart';
import 'package:wonder_souls/src/features/trips/presentation/cubit/blogs_cubit.dart';
import 'package:wonder_souls/src/features/trips/presentation/cubit/saved_articles_cubit.dart';
import 'package:wonder_souls/src/features/trips/presentation/screens/blog_detail_screen.dart';
import 'package:wonder_souls/src/features/trips/presentation/screens/list_article.dart';
import 'package:wonder_souls/src/features/trips/presentation/screens/trip_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Set<String> _likedTrips = {};
  TripData? _activeTrip;

  @override
  void initState() {
    super.initState();
    _fetchUserActiveTrip();
  }

  Future<void> _fetchUserActiveTrip() async {
    final user = sl.isRegistered<AuthLocalDataSource>()
        ? sl<AuthLocalDataSource>().getUser()
        : null;
    final currentUserId = user?.id;

    if (currentUserId == null || currentUserId.isEmpty) {
      if (mounted) {
        setState(() {
          _activeTrip = null;
        });
      }
      return;
    }

    try {
      final apiService = sl<ApiService>();
      final result = await apiService.get<dynamic>(
        ApiConstants.getTrips,
        fromJson: (json) => json,
      );

      if (!mounted) return;

      if (result is Success<dynamic>) {
        final rawData = result.data;
        List<dynamic> items = [];

        if (rawData is List) {
          items = rawData;
        } else if (rawData is Map<String, dynamic>) {
          if (rawData["data"] is List) {
            items = rawData["data"] as List;
          } else if (rawData["items"] is List) {
            items = rawData["items"] as List;
          } else if (rawData["trips"] is List) {
            items = rawData["trips"] as List;
          } else if (rawData["data"] is Map<String, dynamic>) {
            final inner = rawData["data"] as Map<String, dynamic>;
            if (inner["items"] is List) {
              items = inner["items"] as List;
            } else if (inner["trips"] is List) {
              items = inner["trips"] as List;
            } else if (inner["data"] is List) {
              items = inner["data"] as List;
            }
          }
        }

        final List<TripData> fetchedTrips = [];
        for (final item in items) {
          if (item is Map<String, dynamic>) {
            try {
              final tripOwnerId = item["ownerId"]?.toString() ?? item["OwnerId"]?.toString();
              if (tripOwnerId != null && tripOwnerId.isNotEmpty) {
                if (tripOwnerId != currentUserId) continue;
              }
              fetchedTrips.add(TripData.fromJson(item));
            } catch (e) {
              debugPrint("Error parsing trip item: $e");
            }
          }
        }

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final activeList = fetchedTrips
            .where((t) => t.endDate == null || !t.endDate!.isBefore(today))
            .toList();

        if (mounted) {
          setState(() {
            _activeTrip = activeList.isNotEmpty ? activeList.first : null;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _activeTrip = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _activeTrip = null;
        });
      }
    }
  }

  final List<Map<String, dynamic>> _popularDestinations = [
    {
      "name": "Singapore",
      "image":
          "https://images.unsplash.com/photo-1525625293386-3f8f99389edd?w=400&q=80",
      "country": "Singapore",
      "placeId": "singapore_sg",
    },
    {
      "name": "Thailand",
      "image":
          "https://images.unsplash.com/photo-1528181304800-259b08848526?w=400&q=80",
      "country": "Thailand",
      "placeId": "bangkok_th",
    },
    {
      "name": "Malaysia",
      "image":
          "https://images.unsplash.com/photo-1596422846543-75c6fc197f07?w=400&q=80",
      "country": "Malaysia",
      "placeId": "kuala_lumpur_my",
    },
    {
      "name": "Bali",
      "image":
          "https://images.unsplash.com/photo-1537996194471-e657df975ab4?w=400&q=80",
      "country": "Indonesia",
      "placeId": "bali_id",
    },
    {
      "name": "Vietnam",
      "image":
          "https://images.unsplash.com/photo-1528127269322-539801943592?w=400&q=80",
      "country": "Vietnam",
      "placeId": "hanoi_vn",
    },
  ];

  final List<Map<String, dynamic>> _themes = [
    {
      "title": "Family Trips",
      "icon": Icons.family_restroom_rounded,
      "lightBg": Color(0xFFF5F3FF),
      "lightBorder": Color(0xFFDDD6FE),
      "iconColor": Color(0xFF8B5CF6),
      "textColor": Color(0xFF6D28D9),
      "subtitle": "18+ Trips",
      "filter": "Family",
    },
    {
      "title": "Budget Trips",
      "icon": Icons.savings_rounded,
      "lightBg": Color(0xFFF0FDFA),
      "lightBorder": Color(0xFF99F6E4),
      "iconColor": Color(0xFF0D9488),
      "textColor": Color(0xFF0F766E),
      "subtitle": "24+ Trips",
      "filter": "Cheap",
    },
    {
      "title": "Beach Escapes",
      "icon": Icons.beach_access_rounded,
      "lightBg": Color(0xFFFFFBEB),
      "lightBorder": Color(0xFFFDE68A),
      "iconColor": Color(0xFFD97706),
      "textColor": Color(0xFFB45309),
      "subtitle": "15+ Trips",
      "filter": "Beach",
    },
    {
      "title": "Nature & Hills",
      "icon": Icons.landscape_rounded,
      "lightBg": Color(0xFFF0FDF4),
      "lightBorder": Color(0xFFA7F3D0),
      "iconColor": Color(0xFF16A34A),
      "textColor": Color(0xFF15803D),
      "subtitle": "20+ Trips",
      "filter": "Adventure",
    },
    {
      "title": "Adventure",
      "icon": Icons.explore_rounded,
      "lightBg": Color(0xFFEFF6FF),
      "lightBorder": Color(0xFFBFDBFE),
      "iconColor": Color(0xFF2563EB),
      "textColor": Color(0xFF1D4ED8),
      "subtitle": "16+ Trips",
      "filter": "Adventure",
    },
    {
      "title": "Romantic",
      "icon": Icons.favorite_rounded,
      "lightBg": Color(0xFFFFF1F2),
      "lightBorder": Color(0xFFFECDD3),
      "iconColor": Color(0xFFE11D48),
      "textColor": Color(0xFFBE123C),
      "subtitle": "12+ Trips",
      "filter": "Romantic",
    },
    {
      "title": "Culture",
      "icon": Icons.account_balance_rounded,
      "lightBg": Color(0xFFFFF7ED),
      "lightBorder": Color(0xFFFED7AA),
      "iconColor": Color(0xFFEA580C),
      "textColor": Color(0xFFC2410C),
      "subtitle": "10+ Trips",
      "filter": "Culture",
    },
  ];

  final List<BlogModel> _curatedBlogs = [
    BlogModel(
      id: "curated_1",
      title: "10 Hidden Gems in Bali You Must Visit in 2026",
      desc:
          "Escape the tourist crowds and discover secret waterfalls, untouched beaches, and tranquil hillside retreats across the Island of the Gods.\n\nFrom the misty hills of Munduk to the hidden coves of Nusa Penida, Bali offers endless surprises for mindful travelers seeking serenity and cultural authenticity.\n\nMake sure to wake up early for the sunrise over Mount Batur and explore the emerald rice terraces of Jatiluwih, a UNESCO World Heritage site that retains its timeless agricultural traditions.",
      image:
          "https://images.unsplash.com/photo-1537996194471-e657df975ab4?w=800&q=80",
      category: "Destinations",
      readTime: "4 min read",
      author: "Aria Traveler",
      featured: true,
      createdAt: "2026-10-10T10:00:00Z",
      updatedAt: "2026-10-10T10:00:00Z",
    ),
    BlogModel(
      id: "curated_2",
      title: "The Ultimate Guide to Budget Traveling Across Southeast Asia",
      desc:
          "How to explore stunning temples, vibrant night markets, and tropical islands without breaking the bank.\n\nSoutheast Asia remains the gold standard for budget travelers. From \$3 street food meals in Bangkok to affordable sleeper trains in Vietnam, your money stretches further than anywhere else on earth.\n\nLearn our top secrets for booking local transport, finding verified guesthouses, and navigating currency exchange rates with zero unnecessary fees.",
      image:
          "https://images.unsplash.com/photo-1528181304800-259b08848526?w=800&q=80",
      category: "Budget Travel",
      readTime: "6 min read",
      author: "Karan Mehta",
      featured: true,
      createdAt: "2026-10-08T12:30:00Z",
      updatedAt: "2026-10-08T12:30:00Z",
    ),
    BlogModel(
      id: "curated_3",
      title: "Pack Like a Pro: 15 Must-Have Essentials for Solo Trips",
      desc:
          "Smart packing hacks, lightweight gear, and travel essentials every solo backpacker should carry.\n\nPacking light isn't just about avoiding baggage fees; it's about freedom of movement. When your entire life fits in a 40L carry-on, hopping onto ferries and exploring cobblestone streets becomes effortless.\n\nWe break down universal power adapters, quick-dry merino wool layers, portable water filters, and emergency tech backups.",
      image:
          "https://images.unsplash.com/photo-1488646953014-85cb44e25828?w=800&q=80",
      category: "Travel Tips",
      readTime: "5 min read",
      author: "Elena Rostova",
      featured: true,
      createdAt: "2026-10-05T09:15:00Z",
      updatedAt: "2026-10-05T09:15:00Z",
    ),
    BlogModel(
      id: "curated_4",
      title: "A Culinary Journey Through the Street Foods of Singapore",
      desc:
          "From Michelin-starred hawker stalls to secret alleyway laksa, taste the incredible flavors of the Lion City.\n\nSingaporean cuisine is a magnificent melting pot of Malay, Chinese, Indian, and Peranakan traditions. We take you through Maxwell Food Centre, Chinatown Complex, and Old Airport Road.\n\nDon't miss Hainanese Chicken Rice, chili crab with fried mantou, and steaming bowls of aromatic curry laksa.",
      image:
          "https://images.unsplash.com/photo-1525625293386-3f8f99389edd?w=800&q=80",
      category: "Food & Culture",
      readTime: "5 min read",
      author: "Chef Marcus",
      featured: false,
      createdAt: "2026-10-01T14:20:00Z",
      updatedAt: "2026-10-01T14:20:00Z",
    ),
  ];

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
      return "${dateTime.day} ${months[dateTime.month - 1]}";
    } catch (e) {
      return isoString;
    }
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
          style: TextStyle(
            fontSize: 17.5.sp,
            fontWeight: FontWeight.w800,
            color: context.isDark ? Colors.white : const Color(0xFF0F172A),
            letterSpacing: -0.4,
          ),
        ),
        GestureDetector(
          onTap: onViewAll,
          behavior: HitTestBehavior.opaque,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'See All',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: context.primary,
                ),
              ),
              SizedBox(width: 3.w),
              Icon(
                Icons.arrow_forward_rounded,
                color: context.primary,
                size: 14.sp,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    final isDark = context.isDark;

    return GestureDetector(
      onTap: () {
        context.push(SearchScreen.routeName);
      },
      child: Container(
        height: 38.h,
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isDark
                ? const Color(0xFF334155)
                : const Color(0xFFE2E8F0),
            width: 0.8,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              color: const Color(0xFF64748B),
              size: 18.sp,
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                "Where do you want to go?",
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinuePlanning(TripData trip) {
    final imgUrl = TripImageHelper.getDisplayImageUrl(trip);
    final dateRange = (trip.startDate != null && trip.endDate != null)
        ? "${trip.startDate!.day} ${_monthName(trip.startDate!.month)} – ${trip.endDate!.day} ${_monthName(trip.endDate!.month)} ${trip.endDate!.year}"
        : (trip.dateRange.isNotEmpty ? trip.dateRange : "Planned Trip");

    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: context.isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: context.isDark
              ? const Color(0xFF334155)
              : const Color(0xFFF1F5F9),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
            child: CachedNetworkImage(
              imageUrl: imgUrl,
              width: 90.w,
              height: 58.h,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(
                width: 90.w,
                height: 58.h,
                color: context.mutedBackground,
                child: Icon(Icons.flight_takeoff_rounded, color: context.primary),
              ),
            ),
          ),
          SizedBox(width: 12.w),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  trip.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.5.sp,
                    fontWeight: FontWeight.w800,
                    color: context.isDark ? Colors.white : const Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  dateRange,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),

          // Continue Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                final tripToPass = trip.copyWith(imageUrl: imgUrl);
                context.push(TripDetailsScreen.routeName, extra: tripToPass);
              },
              borderRadius: BorderRadius.circular(20.r),
              child: Ink(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F7F5),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Continue",
                      style: TextStyle(
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w700,
                        color: context.primary,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 13.sp,
                      color: context.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    if (month >= 1 && month <= 12) return months[month - 1];
    return '';
  }

  Widget _buildTripsFromTravellers() {
    final curatedTrips = PublicTripsData.getCuratedPublicTrips();
    final baliTrip = curatedTrips.length > 2 ? curatedTrips[2] : curatedTrips.first;
    final thailandTrip = curatedTrips.length > 5 ? curatedTrips[5] : curatedTrips.last;

    final cards = [
      {
        "title": "Bali",
        "image":
            "https://images.unsplash.com/photo-1537996194471-e657df975ab4?w=800&q=80",
        "trip": baliTrip,
      },
      {
        "title": "Thailand",
        "image":
            "https://images.unsplash.com/photo-1528181304800-259b08848526?w=800&q=80",
        "trip": thailandTrip,
      },
    ];

    return Row(
      children: cards.map((item) {
        final title = item["title"] as String;
        final imageUrl = item["image"] as String;
        final trip = item["trip"] as TripData;
        final isLiked = _likedTrips.contains(title);

        return Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 5.w),
            child: GestureDetector(
              onTap: () {
                context.push(TripDetailsScreen.routeName, extra: trip);
              },
              child: Container(
                height: 145.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.r),
                  child: Stack(
                    children: [
                      // Photo
                      Positioned.fill(
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: context.isDark
                                ? const Color(0xFF1E293B)
                                : const Color(0xFFF1F5F9),
                            child: const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: context.isDark
                                ? const Color(0xFF1E293B)
                                : const Color(0xFFF1F5F9),
                            child: Icon(
                              Icons.landscape_rounded,
                              color: context.primary.withAlpha(100),
                              size: 32,
                            ),
                          ),
                        ),
                      ),

                      // Gradient overlay at bottom
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: const [0.4, 1.0],
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.75),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Favorite Heart Button top-right
                      Positioned(
                        top: 8.h,
                        right: 8.w,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isLiked) {
                                _likedTrips.remove(title);
                              } else {
                                _likedTrips.add(title);
                              }
                            });
                          },
                          child: Container(
                            width: 30.w,
                            height: 30.w,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isLiked
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: isLiked
                                  ? const Color(0xFFEF4444)
                                  : context.primary,
                              size: 16.sp,
                            ),
                          ),
                        ),
                      ),

                      // Bottom label
                      Positioned(
                        bottom: 12.h,
                        left: 12.w,
                        child: Text(
                          title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            shadows: const [
                              Shadow(
                                color: Colors.black45,
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPopularDestinations() {
    return SizedBox(
      height: 84.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _popularDestinations.length,
        separatorBuilder: (_, __) => SizedBox(width: 14.w),
        itemBuilder: (context, index) {
          final dest = _popularDestinations[index];
          final name = dest["name"] as String;
          final imageUrl = dest["image"] as String;
          final country = dest["country"] as String;
          final placeId = dest["placeId"] as String;

          return GestureDetector(
            onTap: () {
              final place = PlaceModel(
                placeId: placeId,
                name: name,
                address: country,
                description: "Explore the stunning sights of $name, $country.",
                types: ["popular", "destination"],
              );
              context.push(DestinationDetailsScreen.routeName, extra: place);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Avatar Circle
                Container(
                  width: 60.w,
                  height: 60.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: context.isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF1F5F9),
                        child: Center(
                          child: SizedBox(
                            width: 16.w,
                            height: 16.w,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: context.primary.withAlpha(120),
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: context.primary.withAlpha(20),
                        child: Icon(
                          Icons.location_on_rounded,
                          color: context.primary,
                          size: 24.sp,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 6.h),
                // Label
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w600,
                    color: context.isDark
                        ? const Color(0xFFCBD5E1)
                        : const Color(0xFF334155),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildExploreByTheme() {
    return SizedBox(
      height: 104.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        clipBehavior: Clip.none,
        itemCount: _themes.length,
        separatorBuilder: (_, __) => SizedBox(width: 12.w),
        itemBuilder: (context, index) {
          final theme = _themes[index];
          final title = theme["title"] as String;
          final icon = theme["icon"] as IconData;
          final lightBg = theme["lightBg"] as Color;
          final lightBorder = theme["lightBorder"] as Color;
          final iconColor = theme["iconColor"] as Color;
          final textColor = theme["textColor"] as Color;
          final subtitle = theme["subtitle"] as String;
          final filter = theme["filter"] as String;

          final isDark = context.isDark;
          final bgColor = isDark ? const Color(0xFF1E293B) : lightBg;
          final borderColor =
              isDark ? iconColor.withValues(alpha: 0.25) : lightBorder;
          final effectiveTextColor = isDark ? Colors.white : textColor;

          return GestureDetector(
            onTap: () {
              context.push(ListPublicTripsScreen.routeName, extra: filter);
            },
            child: Container(
              width: 124.w,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 11.h),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: borderColor, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.25)
                        : iconColor.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 34.w,
                        height: 34.w,
                        decoration: BoxDecoration(
                          color: isDark
                              ? iconColor.withValues(alpha: 0.15)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(10.r),
                          boxShadow: isDark
                              ? null
                              : [
                                  BoxShadow(
                                    color: iconColor.withValues(alpha: 0.12),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                        ),
                        child: Center(
                          child: Icon(
                            icon,
                            color: iconColor,
                            size: 19.sp,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 11.sp,
                        color: isDark
                            ? iconColor.withValues(alpha: 0.7)
                            : iconColor.withValues(alpha: 0.6),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5.sp,
                          fontWeight: FontWeight.w800,
                          color: effectiveTextColor,
                          letterSpacing: -0.2,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : iconColor.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBlogsSection() {
    return BlocBuilder<BlogsCubit, BlogsState>(
      builder: (context, state) {
        List<BlogModel> blogs = [];
        bool isLoading = false;

        if (state is BlogsLoading) {
          isLoading = true;
        } else if (state is BlogsLoaded && state.blogs.isNotEmpty) {
          blogs = state.blogs;
        } else {
          blogs = _curatedBlogs;
        }

        if (isLoading) {
          return _buildBlogsSkeleton();
        }

        return SizedBox(
          height: 252.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            clipBehavior: Clip.none,
            itemCount: blogs.length,
            separatorBuilder: (_, __) => SizedBox(width: 14.w),
            itemBuilder: (context, index) {
              final blog = blogs[index];
              return _buildBlogCard(blog);
            },
          ),
        );
      },
    );
  }

  Widget _buildBlogCard(BlogModel blog) {
    final isDark = context.isDark;
    final authorInitial =
        blog.author.isNotEmpty ? blog.author[0].toUpperCase() : 'W';

    return GestureDetector(
      onTap: () {
        context.push(BlogDetailScreen.routeName, extra: blog);
      },
      child: Container(
        width: 242.w,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFFE2E8F0),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Cover Image
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(15.r)),
              child: SizedBox(
                height: 122.h,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: blog.image,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFF1F5F9),
                        child: Center(
                          child: SizedBox(
                            width: 20.w,
                            height: 20.w,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: context.primary.withAlpha(120),
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFF1F5F9),
                        child: Icon(
                          Icons.article_rounded,
                          color: context.primary.withAlpha(120),
                          size: 32.sp,
                        ),
                      ),
                    ),

                    // Gradient overlay at bottom of image
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0.45, 1.0],
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.65),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Category Badge top-left
                    Positioned(
                      top: 8.h,
                      left: 8.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 3.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(6.r),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          blog.category.isNotEmpty
                              ? blog.category.toUpperCase()
                              : 'TRAVEL',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),

                    // Bookmark Button top-right
                    Positioned(
                      top: 8.h,
                      right: 8.w,
                      child: BlocBuilder<SavedArticlesCubit, List<BlogModel>>(
                        builder: (context, savedArticles) {
                          final isSaved = savedArticles.any((a) =>
                              (a.id.isNotEmpty && a.id == blog.id) ||
                              (a.title == blog.title));

                          return GestureDetector(
                            onTap: () {
                              context
                                  .read<SavedArticlesCubit>()
                                  .toggleSave(blog);
                              if (!isSaved) {
                                AppToast.success("Article bookmarked! 🔖");
                              } else {
                                AppToast.info("Removed from bookmarks");
                              }
                            },
                            child: Container(
                              width: 28.w,
                              height: 28.w,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.45),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  width: 0.5,
                                ),
                              ),
                              child: Icon(
                                isSaved
                                    ? Icons.bookmark_rounded
                                    : Icons.bookmark_border_rounded,
                                color: isSaved ? context.primary : Colors.white,
                                size: 16.sp,
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Read Time bottom-left
                    Positioned(
                      bottom: 8.h,
                      left: 8.w,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            color: Colors.white,
                            size: 11.sp,
                          ),
                          SizedBox(width: 3.w),
                          Text(
                            blog.readTime.isNotEmpty
                                ? blog.readTime
                                : '4 min read',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Content
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 10.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          blog.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.5.sp,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            height: 1.25,
                          ),
                        ),
                        SizedBox(height: 5.h),
                        Text(
                          blog.desc.trim().isNotEmpty
                              ? blog.desc.trim().replaceAll('\n', ' ')
                              : "Discover travel tips, hidden gems, and inspiring itineraries...",
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                            height: 1.32,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 20.w,
                                height: 20.w,
                                decoration: BoxDecoration(
                                  color: context.primary.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    authorInitial,
                                    style: TextStyle(
                                      fontSize: 9.5.sp,
                                      fontWeight: FontWeight.w800,
                                      color: context.primary,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 6.w),
                              Flexible(
                                child: Text(
                                  blog.author.isNotEmpty
                                      ? blog.author
                                      : 'WanderSouls',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10.5.sp,
                                    color: isDark
                                        ? const Color(0xFFCBD5E1)
                                        : const Color(0xFF475569),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4.w),
                                child: Text(
                                  "•",
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    color: isDark
                                        ? const Color(0xFF64748B)
                                        : const Color(0xFF94A3B8),
                                  ),
                                ),
                              ),
                              Text(
                                _formatDate(blog.createdAt),
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  color: isDark
                                      ? const Color(0xFF64748B)
                                      : const Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 3.5.h,
                          ),
                          decoration: BoxDecoration(
                            color: context.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Read",
                                style: TextStyle(
                                  fontSize: 10.5.sp,
                                  fontWeight: FontWeight.w700,
                                  color: context.primary,
                                ),
                              ),
                              SizedBox(width: 2.w),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 11.sp,
                                color: context.primary,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlogsSkeleton() {
    final isDark = context.isDark;
    return SizedBox(
      height: 252.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: 3,
        separatorBuilder: (_, __) => SizedBox(width: 14.w),
        itemBuilder: (context, index) {
          return Container(
            width: 242.w,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 122.h,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(15.r),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(12.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 14.h,
                        width: 190.w,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Container(
                        height: 12.h,
                        width: 140.w,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        height: 10.h,
                        width: 210.w,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                      SizedBox(height: 14.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 20.w,
                                height: 20.w,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFE2E8F0),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 6.w),
                              Container(
                                height: 10.h,
                                width: 70.w,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFE2E8F0),
                                  borderRadius: BorderRadius.circular(4.r),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            height: 20.h,
                            width: 50.w,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: context.primary,
      onRefresh: () async {
        await _fetchUserActiveTrip();
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) setState(() {});
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// SEARCH BAR
              _buildSearchBar(),

              SizedBox(height: 14.h),

              /// HERO AI ITINERARY BANNER
              const AiItineraryBanner(),

              /// CONTINUE PLANNING (Only shown when user is logged in & has an active trip)
              if (_activeTrip != null) ...[
                SizedBox(height: 20.h),
                _buildSectionHeader(
                  title: 'Continue Planning',
                  onViewAll: () {
                    final tripToPass = _activeTrip!.copyWith(
                      imageUrl: TripImageHelper.getDisplayImageUrl(_activeTrip!),
                    );
                    context.push(TripDetailsScreen.routeName, extra: tripToPass);
                  },
                ),
                SizedBox(height: 10.h),
                _buildContinuePlanning(_activeTrip!),
              ],

              SizedBox(height: 20.h),

              /// TRIPS FROM TRAVELLERS
              _buildSectionHeader(
                title: 'Trips from Travellers',
                onViewAll: () {
                  context.push(ListPublicTripsScreen.routeName);
                },
              ),
              SizedBox(height: 10.h),
              _buildTripsFromTravellers(),

              SizedBox(height: 20.h),

              /// POPULAR DESTINATIONS
              _buildSectionHeader(
                title: 'Popular Destinations',
                onViewAll: () {
                  context.push(ListDestination.routeName);
                },
              ),
              SizedBox(height: 10.h),
              _buildPopularDestinations(),

              SizedBox(height: 12.h),

              /// EXPLORE BY THEME
              _buildSectionHeader(
                title: 'Explore by Theme',
                onViewAll: () {
                  context.push(ListPublicTripsScreen.routeName);
                },
              ),
              SizedBox(height: 10.h),
              _buildExploreByTheme(),

              SizedBox(height: 22.h),

              /// TRAVEL BLOGS & STORIES
              _buildSectionHeader(
                title: 'Travel Stories & Blogs',
                onViewAll: () {
                  context.push(ListArticle.routeName);
                },
              ),
              SizedBox(height: 10.h),
              _buildBlogsSection(),

              SizedBox(height: 110.h), // Generous spacing to clear the floating bottom navigation bar (extendBody: true)
            ],
          ),
        ),
      ),
    );
  }
}
