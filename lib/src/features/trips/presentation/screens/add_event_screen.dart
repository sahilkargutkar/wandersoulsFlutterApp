import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wonder_souls/src/config/core/injector/injector.dart';
import 'package:wonder_souls/src/config/core/model/place_model.dart';
import 'package:wonder_souls/src/config/core/services/google_map_services.dart';
import 'package:wonder_souls/src/config/core/services/google_places_new_service.dart';
import 'package:wonder_souls/src/config/utils/common_widgets/circular_icon.dart';
import 'package:wonder_souls/src/config/utils/country_helper.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_text.dart';
import 'package:wonder_souls/src/features/trips/model/trip_activity_model.dart';

class AddEventScreen extends StatefulWidget {
  final String dayTitle;
  final String? destination;

  const AddEventScreen({
    super.key,
    required this.dayTitle,
    this.destination,
  });

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<PlaceModel> _searchResults = [];
  final Set<PlaceModel> _selectedPlaces = {};
  bool _isLoading = false;

  String? get _countryCode =>
      CountryHelper.getCountryCode(widget.destination ?? widget.dayTitle);

  // Default suggested events when search is empty
  List<PlaceModel> _defaultSuggestions = [];

  @override
  void initState() {
    super.initState();
    _loadInitialSuggestions();
  }

  Future<void> _loadInitialSuggestions() async {
    final dest = widget.destination?.trim().isNotEmpty == true
        ? widget.destination!
        : (CountryHelper.isIndia(widget.dayTitle) ? "Shillong, India" : widget.dayTitle);

    // 1. Load curated country suggestions
    final curated = CountryHelper.getCuratedPlaces(dest);
    final places = curated.map((p) {
      return PlaceModel(
        name: p['name'] as String,
        placeId: p['placeId'] as String,
        description: p['category'] as String,
        address: p['address'] as String,
        rating: (p['rating'] as num).toDouble(),
        types: [p['category'] as String],
        googleMapsUrl: p['photoUrl'] as String?,
      );
    }).toList();

    _defaultSuggestions = places;
    if (mounted) {
      setState(() {
        _searchResults = List.from(_defaultSuggestions);
      });
    }

    // 2. Fetch live Google Places suggestions restricted by destination & country
    try {
      final googlePlacesService = GooglePlacesNewService();
      final live = await googlePlacesService.searchPlacesByText(
        "top tourist attractions in $dest",
        regionCode: _countryCode,
        pageSize: 10,
      );
      if (live.isNotEmpty && mounted) {
        final livePlaces = live.map((p) {
          final types = (p['types'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              ['attraction'];
          return PlaceModel(
            name: p['displayName']?['text'] ?? p['name'] ?? 'Attraction',
            placeId: p['id'] ?? '',
            description: p['formattedAddress'] ?? dest,
            address: p['formattedAddress'] ?? dest,
            rating: (p['rating'] as num?)?.toDouble() ?? 4.5,
            types: types,
            googleMapsUrl: p['photoUrl'],
          );
        }).toList();

        if (mounted && _searchController.text.trim().isEmpty) {
          setState(() {
            _defaultSuggestions = livePlaces;
            _searchResults = livePlaces;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching Google Places suggestions for $dest: $e");
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();

    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = List.from(_defaultSuggestions);
        _isLoading = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (mounted) {
        setState(() => _isLoading = true);
      }

      try {
        final googleMapsService = sl<GoogleMapsApiService>();
        // Restrict search by destination country code to avoid worldwide results
        final gResult = await googleMapsService.searchPlaces(
          query,
          countryCode: _countryCode,
        );
        if (!mounted) return;

        gResult.fold(
          (_) => setState(() {
            _searchResults = [];
            _isLoading = false;
          }),
          (places) => setState(() {
            _searchResults = places;
            _isLoading = false;
          }),
        );
      } catch (e) {
        debugPrint("Failed to search locations: $e");
        setState(() => _isLoading = false);
      }
    });
  }

  String _getImageUrlForPlace(PlaceModel place) {
    if (place.googleMapsUrl != null &&
        place.googleMapsUrl!.startsWith('http')) {
      return place.googleMapsUrl!;
    }
    return TripActivityModel.getFallbackImage(0, place.name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.surface,
      appBar: AppBar(
        backgroundColor: context.surface,
        elevation: 0,
        leading: Padding(
          padding: EdgeInsets.only(left: 12.w),
          child: CircularIcon(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18.sp,
              color: context.onSurface,
            ),
            onTap: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          "Add Event",
          style: context.text.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Input
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: "Search",
                prefixIcon: Icon(Icons.search, color: context.onSurfaceVariant),
                filled: true,
                fillColor: context.mutedBackground,
                contentPadding: EdgeInsets.symmetric(
                  vertical: 12.h,
                  horizontal: 16.w,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // List of candidate events
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty
                ? Center(
                    child: Text(
                      "No results found",
                      style: context.text.bodyMedium?.copyWith(
                        color: context.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 8.h,
                    ),
                    itemCount: _searchResults.length,
                    separatorBuilder: (context, index) => 12.h.verticalSpace,
                    itemBuilder: (context, index) {
                      final place = _searchResults[index];
                      final isSelected = _selectedPlaces.contains(place);
                      final imgUrl = _getImageUrlForPlace(place);

                      return Container(
                        padding: EdgeInsets.all(10.w),
                        decoration: BoxDecoration(
                          color: context.surface,
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: isSelected
                                ? context.primary
                                : context.borderColor.withAlpha(20),
                            width: isSelected ? 1.5 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: context.softShadow,
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12.r),
                              child: CachedNetworkImage(
                                imageUrl: imgUrl,
                                width: 56.w,
                                height: 56.h,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => Container(
                                  width: 56.w,
                                  height: 56.h,
                                  color: context.shimmerBase,
                                  child: Icon(
                                    Icons.place,
                                    size: 24.sp,
                                    color: context.primary,
                                  ),
                                ),
                              ),
                            ),
                            12.w.horizontalSpace,
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    place.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: context.text.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  4.h.verticalSpace,
                                  Text(
                                    place.description.isNotEmpty
                                        ? place.description
                                        : (place.types.isNotEmpty
                                              ? place.types.first
                                              : "Attraction"),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: context.text.bodySmall?.copyWith(
                                      color: context.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            8.w.horizontalSpace,
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedPlaces.remove(place);
                                  } else {
                                    _selectedPlaces.add(place);
                                  }
                                });
                              },
                              child: Container(
                                width: 32.w,
                                height: 32.h,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? context.primary
                                      : context.primary.withAlpha(25),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isSelected
                                      ? Icons.check_rounded
                                      : Icons.add_rounded,
                                  color: isSelected
                                      ? Colors.white
                                      : context.primary,
                                  size: 20.sp,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Save button
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            decoration: BoxDecoration(
              color: context.surface,
              boxShadow: [
                BoxShadow(
                  color: context.softShadow,
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50.h,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25.r),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.pop(context, _selectedPlaces.toList());
                },
                child: Text(
                  "Save",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
