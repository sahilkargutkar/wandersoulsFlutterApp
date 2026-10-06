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
      "title": "Family\nTrips",
      "icon": Icons.people_alt_rounded,
      "bgColor": Color(0xFFF3E8FF),
      "iconColor": Color(0xFF9333EA),
      "textColor": Color(0xFF6B21A8),
      "filter": "Family",
    },
    {
      "title": "Budget\nTrips",
      "icon": Icons.currency_rupee_rounded,
      "bgColor": Color(0xFFCCFBF1),
      "iconColor": Color(0xFF0D9488),
      "textColor": Color(0xFF115E59),
      "filter": "Budget",
    },
    {
      "title": "Beach\nEscapes",
      "icon": Icons.wb_sunny_rounded,
      "bgColor": Color(0xFFFEF3C7),
      "iconColor": Color(0xFFD97706),
      "textColor": Color(0xFF92400E),
      "filter": "Beach",
    },
    {
      "title": "Nature\n& Hills",
      "icon": Icons.landscape_rounded,
      "bgColor": Color(0xFFDCFCE7),
      "iconColor": Color(0xFF16A34A),
      "textColor": Color(0xFF166534),
      "filter": "Nature",
    },
  ];

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
    return Row(
      children: _themes.map((theme) {
        final title = theme["title"] as String;
        final icon = theme["icon"] as IconData;
        final bgColor = theme["bgColor"] as Color;
        final iconColor = theme["iconColor"] as Color;
        final textColor = theme["textColor"] as Color;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: GestureDetector(
              onTap: () {
                context.push(ListPublicTripsScreen.routeName);
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 6.w),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      color: iconColor,
                      size: 20.sp,
                    ),
                    SizedBox(width: 5.w),
                    Flexible(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 10.5.sp,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                          height: 1.15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
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

              SizedBox(height: 80.h), // Spacing for bottom bar
            ],
          ),
        ),
      ),
    );
  }
}
