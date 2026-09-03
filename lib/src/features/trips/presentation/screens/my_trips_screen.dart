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
import 'package:wonder_souls/src/config/utils/trip_image_helper.dart';
import 'package:wonder_souls/src/features/auth/data/datasource/auth_local_data_source.dart';

class MyTripsScreen extends StatefulWidget {
  final ValueNotifier<String>? searchNotifier;

  const MyTripsScreen({super.key, this.searchNotifier});

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

        final currentUser = sl<AuthLocalDataSource>().getUser();
        final currentUserId = currentUser?.id;

        final List<TripData> fetchedTrips = [];
        for (final item in items) {
          if (item is Map<String, dynamic>) {
            try {
              final tripOwnerId = item["ownerId"]?.toString() ?? item["OwnerId"]?.toString();
              if (currentUserId != null && currentUserId.isNotEmpty && tripOwnerId != null && tripOwnerId.isNotEmpty) {
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
        setState(() {
          _activeTrips = fetchedTrips
              .where((t) => t.endDate == null || !t.endDate!.isBefore(today))
              .toList();
          _passedTrips = fetchedTrips
              .where((t) => t.endDate != null && t.endDate!.isBefore(today))
              .toList();
          _isLoading = false;
        });
      } else if (result is Failure<dynamic>) {
        if (result.statusCode == 404) {
          setState(() {
            _activeTrips = [];
            _passedTrips = [];
            _isLoading = false;
            _errorMessage = null;
          });
        } else {
          setState(() {
            _errorMessage = result.message;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
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
                          Icon(
                            Icons.error_outline,
                            size: 48.sp,
                            color: context.colors.error,
                          ),
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
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                            child: const Text("Retry"),
                          ),
                        ],
                      ),
                    ),
                  )
                : widget.searchNotifier != null
                    ? ValueListenableBuilder<String>(
                        valueListenable: widget.searchNotifier!,
                        builder: (context, query, child) {
                          final filteredActive = _activeTrips.where((t) {
                            final nameMatch = t.name.toLowerCase().contains(query.toLowerCase());
                            final destMatch = t.mainDestination.toLowerCase().contains(query.toLowerCase());
                            return nameMatch || destMatch;
                          }).toList();
                          final filteredPassed = _passedTrips.where((t) {
                            final nameMatch = t.name.toLowerCase().contains(query.toLowerCase());
                            final destMatch = t.mainDestination.toLowerCase().contains(query.toLowerCase());
                            return nameMatch || destMatch;
                          }).toList();
                          return TabBarView(
                            controller: _tabController,
                            children: [
                              _buildTripsList(filteredActive),
                              _buildTripsList(filteredPassed),
                            ],
                          );
                        },
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
      return RefreshIndicator(
        onRefresh: _fetchTrips,
        color: context.primary,
        child: _buildEmptyState(),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchTrips,
      color: context.primary,
      child: ListView.builder(
        padding: EdgeInsets.only(
          left: 16.w,
          right: 16.w,
          top: 16.h,
          bottom: 88.h,
        ),
        itemCount: trips.length,
        itemBuilder: (context, index) {
          final trip = trips[index];
          return GestureDetector(
            onTap: () {
              final resolvedImg = TripImageHelper.getDisplayImageUrl(trip);
              final tripToPass = trip.copyWith(imageUrl: resolvedImg);
              context.push(TripDetailsScreen.routeName, extra: tripToPass);
            },
            child: TripCard(trip: trip),
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
