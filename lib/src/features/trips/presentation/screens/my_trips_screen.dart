import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:wonder_souls/src/config/core/injector/injector.dart';
import 'package:wonder_souls/src/config/core/services/api_services.dart';
import 'package:wonder_souls/src/config/model/failure.dart';
import 'package:wonder_souls/src/config/model/success.dart';
import 'package:wonder_souls/src/config/utils/api_constant.dart';
import 'package:wonder_souls/src/features/trips/model/trip.dart';
import 'package:wonder_souls/src/features/trips/presentation/screens/trip_details_screen.dart';
import 'package:wonder_souls/src/features/trips/presentation/widgets/trip_card.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_text.dart';

class MyTripsScreen extends StatefulWidget {
  const MyTripsScreen({super.key});

  @override
  State<MyTripsScreen> createState() => _MyTripsScreenState();
}

class _MyTripsScreenState extends State<MyTripsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<TripData> _activeTrips = [];
  List<TripData> _passedTrips = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchTrips();
  }

  Future<void> _fetchTrips() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiService = sl<ApiService>();
      final result = await apiService.get<List<dynamic>>(
        ApiConstants.getTrips,
        fromJson: (json) => json as List<dynamic>,
      );

      if (result is Success<List<dynamic>>) {
        final List<TripData> fetchedTrips = result.data
            .map((item) => TripData.fromJson(item as Map<String, dynamic>))
            .toList();

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        setState(() {
          _activeTrips = fetchedTrips.where((t) => t.endDate == null || !t.endDate!.isBefore(today)).toList();
          _passedTrips = fetchedTrips.where((t) => t.endDate != null && t.endDate!.isBefore(today)).toList();
          _isLoading = false;
        });
      } else if (result is Failure<List<dynamic>>) {
        setState(() {
          _errorMessage = result.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatDateRange(DateTime? start, DateTime? end) {
    if (start == null || end == null) return "Dates Unknown";
    const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return "${months[start.month - 1]} ${start.day} - ${months[end.month - 1]} ${end.day}, ${end.year}";
  }

  String _getCountryFlag(String destination) {
    final lower = destination.toLowerCase();
    if (lower.contains("tokyo") || lower.contains("japan")) return "🇯🇵";
    if (lower.contains("paris") || lower.contains("france")) return "🇫🇷";
    if (lower.contains("london") || lower.contains("uk") || lower.contains("united kingdom")) return "🇬🇧";
    if (lower.contains("rome") || lower.contains("italy")) return "🇮🇹";
    if (lower.contains("new york") || lower.contains("usa") || lower.contains("united states")) return "🇺🇸";
    if (lower.contains("sydney") || lower.contains("australia")) return "🇦🇺";
    if (lower.contains("delhi") || lower.contains("india") || lower.contains("mumbai")) return "🇮🇳";
    return "🌍";
  }

  String _getTripImage(String destination) {
    final lower = destination.toLowerCase();
    if (lower.contains("tokyo") || lower.contains("japan")) {
      return "https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?w=800";
    }
    if (lower.contains("paris") || lower.contains("france")) {
      return "https://images.unsplash.com/photo-1502602898657-3e91760cbb34?w=800";
    }
    if (lower.contains("london")) {
      return "https://images.unsplash.com/photo-1513635269975-59663e0ac1ad?w=800";
    }
    if (lower.contains("rome") || lower.contains("italy")) {
      return "https://images.unsplash.com/photo-1552832230-c0197dd311b5?w=800";
    }
    if (lower.contains("new york") || lower.contains("usa")) {
      return "https://images.unsplash.com/photo-1496442226666-8d4d0e62e6e9?w=800";
    }
    if (lower.contains("sydney") || lower.contains("australia")) {
      return "https://images.unsplash.com/photo-1506973035872-a4ec16b8e8d9?w=800";
    }
    if (lower.contains("india")) {
      return "https://images.unsplash.com/photo-1524492412937-b28074a5d7da?w=800";
    }
    return "https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?w=800";
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Tab Bar
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: context.mutedBackground,
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: context.primary,
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: context.primary.withAlpha(30),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              labelColor: Colors.white,
              unselectedLabelColor: context.onSurfaceVariant,
              labelStyle: context.text.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: context.text.titleSmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              splashBorderRadius: BorderRadius.circular(12.r),
              tabs: const [
                Tab(text: 'Active'),
                Tab(text: 'Passed'),
              ],
            ),
          ),

          // Tab Bar View / States
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(color: context.primary),
                  )
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 32.w),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, size: 48.sp, color: context.colors.error),
                              16.h.verticalSpace,
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: context.text.bodyMedium?.copyWith(
                                  color: context.colors.onSurfaceVariant,
                                ),
                              ),
                              16.h.verticalSpace,
                              ElevatedButton(
                                onPressed: _fetchTrips,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: context.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                                ),
                                child: const Text("Retry"),
                              ),
                            ],
                          ),
                        ),
                      )
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildTripsList(_activeTrips),
                          _buildTripsList(_passedTrips),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripsList(List<TripData> trips) {
    if (trips.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _fetchTrips,
      color: context.primary,
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: trips.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => context.push(
              TripDetailsScreen.routeName,
              extra: trips[index],
            ),
            child: TripCard(trip: trips[index]),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.primaryTint,
              ),
              child: Icon(
                Icons.location_on_outlined,
                size: 36.sp,
                color: context.primary.withAlpha(150),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'No trips yet',
              style: context.text.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: context.onSurface,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Start planning your next adventure',
              style: context.text.bodyMedium?.copyWith(
                color: context.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
