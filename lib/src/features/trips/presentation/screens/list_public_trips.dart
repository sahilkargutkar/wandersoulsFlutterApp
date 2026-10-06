import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wonder_souls/src/config/utils/common_widgets/app_search_bar.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_text.dart';
import 'package:wonder_souls/src/features/trips/model/public_trips_data.dart';
import 'package:wonder_souls/src/features/trips/model/trip.dart';
import 'package:wonder_souls/src/features/trips/presentation/widgets/public_trip_card.dart';

class ListPublicTripsScreen extends StatefulWidget {
  const ListPublicTripsScreen({super.key});

  static const String routeName = "/ListPublicTrips";

  @override
  State<ListPublicTripsScreen> createState() => _ListPublicTripsScreenState();
}

class _ListPublicTripsScreenState extends State<ListPublicTripsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String _selectedCategory = "All";

  final List<String> _categories = [
    "All",
    "Balanced",
    "Luxury",
    "Cheap",
    "Romantic",
    "Adventure",
    "Culture",
  ];

  late final List<TripData> _allTrips;

  @override
  void initState() {
    super.initState();
    _allTrips = PublicTripsData.getCuratedPublicTrips();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _allTrips.where((trip) {
      final matchesQuery = _searchQuery.isEmpty ||
          trip.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          trip.mainDestination.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          trip.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          trip.travelTastes.any((t) => t.toLowerCase().contains(_searchQuery.toLowerCase()));

      final matchesCategory = _selectedCategory == "All" ||
          trip.category.toLowerCase() == _selectedCategory.toLowerCase() ||
          trip.travelTastes.any((t) => t.toLowerCase().contains(_selectedCategory.toLowerCase()));

      return matchesQuery && matchesCategory;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 62.w,
        centerTitle: true,
        leading: Padding(
          padding: EdgeInsets.only(left: 20.w, top: 7.h, bottom: 7.h),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.mutedBackground,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16.sp,
                color: context.onSurface,
              ),
            ),
          ),
        ),
        title: Text(
          'Public Community Trips',
          style: context.text.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 18.sp,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: AppSearchBar(
              hintText: "Search public trips, destinations...",
              controller: _searchController,
              onChanged: (val) {
                setState(() => _searchQuery = val);
              },
              onClear: () {
                setState(() {
                  _searchController.clear();
                  _searchQuery = "";
                });
              },
            ),
          ),

          // Category Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Row(
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: EdgeInsets.only(right: 8.w),
                  child: FilterChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = cat;
                      });
                    },
                    backgroundColor: context.mutedBackground,
                    selectedColor: context.primaryTint,
                    labelStyle: TextStyle(
                      color: isSelected ? context.primary : context.onSurfaceVariant,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 12.sp,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                      side: BorderSide(
                        color: isSelected ? context.primary : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    showCheckmark: false,
                  ),
                );
              }).toList(),
            ),
          ),

          // Trips List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.public_off_rounded,
                          size: 48.sp,
                          color: context.onSurfaceVariant.withAlpha(80),
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          "No matching public trips found",
                          style: context.text.bodyMedium?.copyWith(
                            color: context.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final trip = filtered[index];
                      return Padding(
                        padding: EdgeInsets.only(bottom: 16.h),
                        child: PublicTripCard(
                          trip: trip,
                          cardWidth: double.infinity,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
