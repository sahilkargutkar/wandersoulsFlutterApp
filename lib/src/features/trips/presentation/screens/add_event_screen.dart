import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wonder_souls/src/config/core/injector/injector.dart';
import 'package:wonder_souls/src/config/core/model/place_model.dart';
import 'package:wonder_souls/src/config/core/services/api_services.dart';
import 'package:wonder_souls/src/config/core/services/google_map_services.dart';
import 'package:wonder_souls/src/config/utils/common_widgets/circular_icon.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_text.dart';

class AddEventScreen extends StatefulWidget {
  final String dayTitle;

  const AddEventScreen({super.key, required this.dayTitle});

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<PlaceModel> _searchResults = [];
  final Set<PlaceModel> _selectedPlaces = {};
  bool _isLoading = false;

  // Default suggested events when search is empty
  final List<PlaceModel> _defaultSuggestions = [
    PlaceModel(
      name: "Afuri Harajuku",
      placeId: "afuri_harajuku",
      description: "Ramen Restaurant",
      address: "1-1-7 Sendagaya, Shibuya-ku, Tokyo",
      rating: 4.5,
      types: ["restaurant", "food"],
    ),
    PlaceModel(
      name: "Akiba Ichi",
      placeId: "akiba_ichi",
      description: "Food Court",
      address: "Akihabara, Chiyoda-ku, Tokyo",
      rating: 4.3,
      types: ["food", "restaurant"],
    ),
    PlaceModel(
      name: "Akihabara Electric Town",
      placeId: "akihabara_town",
      description: "Business Park & Shopping",
      address: "Chiyoda-ku, Tokyo",
      rating: 4.7,
      types: ["store", "attraction"],
    ),
    PlaceModel(
      name: "Asakusa Hanayashiki",
      placeId: "asakusa_hanayashiki",
      description: "Amusement Park",
      address: "Asakusa, Taito-ku, Tokyo",
      rating: 4.4,
      types: ["attraction", "park"],
    ),
    PlaceModel(
      name: "Asakusa Shrine",
      placeId: "asakusa_shrine",
      description: "Shinto Shrine",
      address: "Asakusa, Taito-ku, Tokyo",
      rating: 4.6,
      types: ["attraction", "landmark"],
    ),
    PlaceModel(
      name: "Batejyu Shibuya Store",
      placeId: "batejyu_shibuya",
      description: "Okonomiyaki Restaurant",
      address: "Shibuya, Tokyo",
      rating: 4.2,
      types: ["restaurant"],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _searchResults = List.from(_defaultSuggestions);
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
      setState(() => _isLoading = true);

      try {
        final apiService = sl<ApiService>();
        final locationsResult = await apiService.getLocations(1, 15, query);

        locationsResult.fold(
          (failure) async {
            // Fallback to Google Maps API if locations endpoint has no results
            final googleMapsService = sl<GoogleMapsApiService>();
            final gResult = await googleMapsService.searchPlaces(query);
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
          },
          (places) {
            if (places.isNotEmpty) {
              setState(() {
                _searchResults = places;
                _isLoading = false;
              });
            } else {
              _fallbackGoogleMaps(query);
            }
          },
        );
      } catch (_) {
        setState(() => _isLoading = false);
      }
    });
  }

  Future<void> _fallbackGoogleMaps(String query) async {
    try {
      final googleMapsService = sl<GoogleMapsApiService>();
      final gResult = await googleMapsService.searchPlaces(query);
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
    } catch (_) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
    }
  }

  String _getImageUrlForPlace(PlaceModel place) {
    if (place.googleMapsUrl != null && place.googleMapsUrl!.startsWith('http')) {
      return place.googleMapsUrl!;
    }
    final nameLower = place.name.toLowerCase();
    if (nameLower.contains("ramen") || nameLower.contains("food") || nameLower.contains("restaurant") || nameLower.contains("afuri") || nameLower.contains("sushi")) {
      return "https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=400";
    }
    if (nameLower.contains("shrine") || nameLower.contains("temple") || nameLower.contains("jingu") || nameLower.contains("asakusa")) {
      return "https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?w=400";
    }
    if (nameLower.contains("park") || nameLower.contains("tower") || nameLower.contains("electric")) {
      return "https://images.unsplash.com/photo-1503899036084-c55cdd92da26?w=400";
    }
    return "https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?w=400";
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
                contentPadding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
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
                        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
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
                                      child: Icon(Icons.place, size: 24.sp, color: context.primary),
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
                                            : (place.types.isNotEmpty ? place.types.first : "Attraction"),
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
                                      isSelected ? Icons.check_rounded : Icons.add_rounded,
                                      color: isSelected ? Colors.white : context.primary,
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
