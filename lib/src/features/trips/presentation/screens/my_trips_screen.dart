import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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

  // Static trip data
  final List<TripData> _activeTrips = [
    TripData(
      name: 'Tokyo, Japan',
      flag: '🇯🇵',
      dateRange: 'Dec 12 - Dec 14, 2023',
      tripType: 'A Couple',
      category: 'Luxury',
      imageUrl:
          'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?w=800',
    ),
    TripData(
      name: 'Paris, France',
      flag: '🇫🇷',
      dateRange: 'Jan 5 - Jan 12, 2024',
      tripType: 'Solo',
      category: 'Adventure',
      imageUrl:
          'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?w=800',
    ),
  ];

  final List<TripData> _passedTrips = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
            decoration: BoxDecoration(
              color: context.onSurfaceVariant.withAlpha(20),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: context.primary,
                borderRadius: BorderRadius.circular(12.r),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: context.onSurface,
              labelStyle: context.text.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: context.text.titleMedium,
              tabs: const [
                Tab(text: 'Active'),
                Tab(text: 'Passed'),
              ],
            ),
          ),

          // Tab Bar View
          Expanded(
            child: TabBarView(
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

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: trips.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () =>
              Navigator.pushNamed(context, TripDetailsScreen.routeName),
          child: TripCard(trip: trips[index]),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_on_outlined,
            size: 64.sp,
            color: context.onSurface.withAlpha(76),
          ),
          SizedBox(height: 16.h),
          Text(
            'No trips yet',
            style: context.text.titleLarge?.copyWith(
              color: context.onSurface.withAlpha(153),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Start planning your next adventure',
            style: context.text.bodyMedium?.copyWith(
              color: context.onSurface.withAlpha(10),
            ),
          ),
        ],
      ),
    );
  }
}

// Trip data model
class TripData {
  final String name;
  final String flag;
  final String dateRange;
  final String tripType;
  final String category;
  final String imageUrl;

  TripData({
    required this.name,
    required this.flag,
    required this.dateRange,
    required this.tripType,
    required this.category,
    required this.imageUrl,
  });
}
