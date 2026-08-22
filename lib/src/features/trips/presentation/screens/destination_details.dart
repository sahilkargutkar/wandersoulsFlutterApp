import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:wonder_souls/src/config/core/model/place_model.dart';
import 'package:wonder_souls/src/config/utils/common_widgets/common_button.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_text.dart';
import 'package:wonder_souls/src/config/core/services/google_places_new_service.dart';
import 'package:wonder_souls/src/features/trips/presentation/screens/trip_wizard/trip_wizard_screen.dart';

class DestinationDetailsScreen extends StatefulWidget {
  const DestinationDetailsScreen({super.key, required this.place});

  static const String routeName = "/DestinationDetailsScreen";
  final PlaceModel place;

  @override
  State<DestinationDetailsScreen> createState() =>
      _DestinationDetailsScreenState();
}

class _DestinationDetailsScreenState extends State<DestinationDetailsScreen> {
  final GooglePlacesNewService _placesService = GooglePlacesNewService();
  bool _isLoading = true;
  Map<String, dynamic>? _details;
  final List<String> _resolvedPhotos = [];
  bool _isOpeningHoursExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadDestinationDetails();
  }

  Future<void> _loadDestinationDetails() async {
    setState(() => _isLoading = true);

    String? placeId = widget.place.placeId;

    try {
      if (placeId.isEmpty) {
        // Fallback to text search if placeId is empty
        placeId = await _placesService.searchPlaceId(widget.place.name);
      }

      if (placeId != null && placeId.isNotEmpty) {
        final details = await _placesService.getPlaceDetails(placeId);
        if (details != null) {
          _details = details;

          final photosList = details["photos"] as List?;
          if (photosList != null && photosList.isNotEmpty) {
            // Resolve up to 4 photos for gallery & hero image
            final maxPhotos = photosList.length > 4 ? 4 : photosList.length;
            for (var i = 0; i < maxPhotos; i++) {
              final pName = photosList[i]["name"];
              if (pName != null) {
                final uri = await _placesService.getPhotoUri(pName);
                if (uri != null) {
                  _resolvedPhotos.add(uri);
                }
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Error loading destination details: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _launchWebsite(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _launchPhone(String phone) async {
    final uri = Uri.parse("tel:${phone.replaceAll(' ', '')}");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Resolve place fields dynamically
    final name = _details?["displayName"]?["text"] ?? widget.place.name;
    final address = _details?["formattedAddress"] ?? widget.place.address;
    final rating = _details?["rating"] != null
        ? (_details!["rating"] as num).toDouble()
        : (widget.place.rating ?? 4.5);
    final userRatingsCount =
        _details?["userRatingCount"] as int? ??
        (widget.place.userRatingsTotal ?? 1250);

    // 2. Resolve description / generative overview
    final String description =
        _details?["generativeSummary"]?["overview"]?["text"] ??
        _details?["editorialSummary"]?["text"] ??
        widget.place.description.replaceAll(widget.place.name, name);

    // 3. Resolve hero image
    final String heroImageUrl = _resolvedPhotos.isNotEmpty
        ? _resolvedPhotos[0]
        : "https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?w=1200";

    // 4. Resolve gallery list
    final List<String> galleryImages = _resolvedPhotos.length > 1
        ? _resolvedPhotos.sublist(1)
        : [
            "https://images.unsplash.com/photo-1542051841857-5f90071e7989?w=600",
            "https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?w=600",
            "https://images.unsplash.com/photo-1492571350019-22de08371fd3?w=600",
          ];

    // 5. Construct updated PlaceModel to pass to the Wizard
    final updatedPlaceModel = PlaceModel(
      name: name,
      placeId: _details?["id"] ?? widget.place.placeId,
      description: description,
      address: address,
      rating: rating,
      userRatingsTotal: userRatingsCount,
      latitude: _details?["location"]?["latitude"] != null
          ? (_details!["location"]["latitude"] as num).toDouble()
          : widget.place.latitude,
      longitude: _details?["location"]?["longitude"] != null
          ? (_details!["location"]["longitude"] as num).toDouble()
          : widget.place.longitude,
      googleMapsUrl: _details?["googleMapsUri"] ?? widget.place.googleMapsUrl,
      types: _details?["types"] != null
          ? List<String>.from(_details!["types"])
          : widget.place.types,
    );

    // 6. Build dynamic sections
    final List<Map<String, dynamic>> dynamicSections = [];

    // Opening Hours
    final openingHoursList =
        _details?["regularOpeningHours"]?["weekdayDescriptions"] as List?;
    if (openingHoursList != null && openingHoursList.isNotEmpty) {
      dynamicSections.add({
        "icon": Icons.access_time_filled_rounded,
        "title": "Opening Hours",
        "isHours": true,
        "content": openingHoursList.cast<String>(),
      });
    }

    // Phone
    final phone = _details?["internationalPhoneNumber"] as String?;
    if (phone != null && phone.isNotEmpty) {
      dynamicSections.add({
        "icon": Icons.phone_rounded,
        "title": "Contact",
        "actionText": phone,
        "onTap": () => _launchPhone(phone),
      });
    }

    // Website
    final website = _details?["websiteUri"] as String?;
    if (website != null && website.isNotEmpty) {
      dynamicSections.add({
        "icon": Icons.language_rounded,
        "title": "Official Website",
        "actionText": website,
        "onTap": () => _launchWebsite(website),
      });
    }

    // Amenities & Attributes (Good for kids, groups, wheelchair accessible)
    final List<String> amenities = [];
    if (_details?["goodForChildren"] == true) {
      amenities.add("Family Friendly");
    }
    if (_details?["goodForGroups"] == true) {
      amenities.add("Good for Groups");
    }
    if (_details?["accessibilityOptions"]?["wheelchairAccessibleEntrance"] ==
        true) {
      amenities.add("Wheelchair Accessible");
    }

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: SizedBox(
          width: double.infinity,
          child: CommonButton(
            title: "Start Trip",
            useGradient: true,
            icon: Icons.explore_rounded,
            onPressed: () {
              context.push(
                TripWizardScreen.routeName,
                extra: updatedPlaceModel,
              );
            },
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0D9F6E)),
              ),
            )
          : CustomScrollView(
              slivers: [
                /// APP BAR IMAGE
                SliverAppBar(
                  expandedHeight: 340.h,
                  pinned: true,
                  backgroundColor: context.colors.surface,
                  leading: Padding(
                    padding: EdgeInsets.only(left: 14.w, top: 6.h),
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        decoration: BoxDecoration(
                          color: context.colors.surface.withAlpha(230),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(10),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18.sp,
                          color: context.colors.onSurface,
                        ),
                      ),
                    ),
                  ),
                  actions: [
                    Container(
                      margin: EdgeInsets.only(right: 8.w, top: 6.h),
                      decoration: BoxDecoration(
                        color: context.colors.surface.withAlpha(230),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(10),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: () {},
                        icon: Icon(
                          Icons.bookmark_border_rounded,
                          color: context.colors.onSurface,
                          size: 20.sp,
                        ),
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(right: 14.w, top: 6.h),
                      decoration: BoxDecoration(
                        color: context.colors.surface.withAlpha(230),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(10),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: () {
                          final mapUrl =
                              updatedPlaceModel.googleMapsUrl ??
                              "https://maps.google.com/?q=${Uri.encodeComponent(name)}";
                          final shareText =
                              "Explore $name in $address on WanderSouls! 🌍✈️\nLocation Link: $mapUrl";
                          // ignore: deprecated_member_use
                          Share.share(shareText);
                        },
                        icon: Icon(
                          Icons.share_outlined,
                          color: context.colors.onSurface,
                          size: 20.sp,
                        ),
                      ),
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        Hero(
                          tag: updatedPlaceModel.placeId,
                          child: Image.network(
                            heroImageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Image.network(
                                  "https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?w=1200",
                                  fit: BoxFit.cover,
                                ),
                          ),
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withAlpha(30),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                /// CONTENT
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 120.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// TITLE
                        Text(
                          name,
                          style: context.text.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: context.colors.onSurface,
                            letterSpacing: -0.3,
                          ),
                        ),

                        8.h.verticalSpace,

                        /// RATING & REVIEWS
                        Row(
                          children: [
                            Icon(
                              Icons.star_rounded,
                              color: const Color(0xFFF59E0B),
                              size: 20.sp,
                            ),
                            4.w.horizontalSpace,
                            Text(
                              rating.toStringAsFixed(1),
                              style: context.text.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: context.colors.onSurface,
                              ),
                            ),
                            8.w.horizontalSpace,
                            Text(
                              "($userRatingsCount reviews)",
                              style: context.text.bodyMedium?.copyWith(
                                color: context.colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),

                        12.h.verticalSpace,

                        /// ADDRESS
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              color: context.colors.primary,
                              size: 18.sp,
                            ),
                            8.w.horizontalSpace,
                            Expanded(
                              child: Text(
                                address,
                                style: context.text.bodyMedium?.copyWith(
                                  color: context.colors.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),

                        24.h.verticalSpace,

                        /// GENERATIVE SUMMARY
                        if (_details?["generativeSummary"]?["overview"]?["text"] !=
                            null)
                          Container(
                            padding: EdgeInsets.all(16.w),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  context.colors.primary.withAlpha(15),
                                  const Color(0xFFF59E0B).withAlpha(10),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20.r),
                              border: Border.all(
                                color: context.colors.primary.withAlpha(30),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.auto_awesome_rounded,
                                      size: 16.sp,
                                      color: context.colors.primary,
                                    ),
                                    8.w.horizontalSpace,
                                    Text(
                                      "AI Overview Summary",
                                      style: context.text.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: context.colors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                10.h.verticalSpace,
                                Text(
                                  description,
                                  style: context.text.bodyMedium?.copyWith(
                                    color: context.colors.onSurfaceVariant,
                                    height: 1.6,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else ...[
                          /// DESCRIPTION
                          Text(
                            description.isNotEmpty
                                ? description
                                : "Discover the vibrant highlights of $name, where modernity meets tradition in perfect harmony. From stunning views to historical landmarks, $name offers a memorable blend of experiences.",
                            style: context.text.bodyLarge?.copyWith(
                              color: context.colors.onSurfaceVariant,
                              height: 1.6,
                            ),
                          ),
                        ],

                        /// AMENITIES / TAGS
                        if (amenities.isNotEmpty) ...[
                          24.h.verticalSpace,
                          Wrap(
                            spacing: 8.w,
                            runSpacing: 8.h,
                            children: amenities.map((amenity) {
                              return Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12.w,
                                  vertical: 6.h,
                                ),
                                decoration: BoxDecoration(
                                  color: context.colors.primary.withAlpha(20),
                                  borderRadius: BorderRadius.circular(30.r),
                                  border: Border.all(
                                    color: context.colors.primary.withAlpha(40),
                                  ),
                                ),
                                child: Text(
                                  amenity,
                                  style: context.text.bodySmall?.copyWith(
                                    color: context.colors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],

                        28.h.verticalSpace,

                        /// GALLERY TITLE
                        Text(
                          "Gallery",
                          style: context.text.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: context.colors.onSurface,
                          ),
                        ),

                        14.h.verticalSpace,

                        /// GALLERY
                        SizedBox(
                          height: 90.h,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: galleryImages.length,
                            separatorBuilder: (_, __) => 12.w.horizontalSpace,
                            itemBuilder: (context, index) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(16.r),
                                child: Image.network(
                                  galleryImages[index],
                                  width: 120.w,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                        color: context.mutedBackground,
                                        width: 120.w,
                                        child: Icon(
                                          Icons.image,
                                          color:
                                              context.colors.onSurfaceVariant,
                                        ),
                                      ),
                                ),
                              );
                            },
                          ),
                        ),

                        28.h.verticalSpace,

                        /// SECTIONS (Hours, Phone, Website)
                        ...dynamicSections.map((section) {
                          final isHours = section["isHours"] == true;
                          return Padding(
                            padding: EdgeInsets.only(bottom: 12.h),
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                border: Border(
                                  bottom: BorderSide(
                                    color: context.borderColor.withAlpha(30),
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  GestureDetector(
                                    onTap: isHours
                                        ? () {
                                            setState(() {
                                              _isOpeningHoursExpanded =
                                                  !_isOpeningHoursExpanded;
                                            });
                                          }
                                        : section["onTap"] as VoidCallback?,
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(8.w),
                                          decoration: BoxDecoration(
                                            color: context.primaryTint,
                                            borderRadius: BorderRadius.circular(
                                              10.r,
                                            ),
                                          ),
                                          child: Icon(
                                            section["icon"] as IconData,
                                            size: 18.sp,
                                            color: context.primary,
                                          ),
                                        ),
                                        12.w.horizontalSpace,
                                        Expanded(
                                          child: Text(
                                            section["title"] as String,
                                            style: context.text.titleSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                  color:
                                                      context.colors.onSurface,
                                                ),
                                          ),
                                        ),
                                        if (isHours)
                                          Icon(
                                            _isOpeningHoursExpanded
                                                ? Icons
                                                      .keyboard_arrow_up_rounded
                                                : Icons
                                                      .keyboard_arrow_down_rounded,
                                            color:
                                                context.colors.onSurfaceVariant,
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (isHours && _isOpeningHoursExpanded) ...[
                                    16.h.verticalSpace,
                                    ...(section["content"] as List<String>).map(
                                      (desc) => Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 4.h,
                                        ),
                                        child: Text(
                                          desc,
                                          style: context.text.bodyMedium
                                              ?.copyWith(
                                                color: context
                                                    .colors
                                                    .onSurfaceVariant,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ],
                                  if (!isHours &&
                                      section["actionText"] != null) ...[
                                    12.h.verticalSpace,
                                    InkWell(
                                      onTap: section["onTap"] as VoidCallback?,
                                      child: Text(
                                        section["actionText"] as String,
                                        style: context.text.bodyMedium
                                            ?.copyWith(
                                              color: context.colors.primary,
                                              fontWeight: FontWeight.w600,
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
