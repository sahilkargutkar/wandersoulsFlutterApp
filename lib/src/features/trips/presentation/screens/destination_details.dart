import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import 'package:wonder_souls/src/config/core/model/place_model.dart';
import 'package:wonder_souls/src/config/utils/common_widgets/common_button.dart';

import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_text.dart';
import 'package:wonder_souls/src/features/trips/presentation/screens/trip_wizard/trip_wizard_screen.dart';

class DestinationDetailsScreen extends StatelessWidget {
  const DestinationDetailsScreen({super.key, required this.place});

  static const String routeName = "/DestinationDetailsScreen";

  final PlaceModel place;

  @override
  Widget build(BuildContext context) {
    final sections = [
      {
        "icon": Icons.flight_takeoff_rounded,
        "title": "Getting to Tokyo:",
        "description":
            "Tokyo is easily accessible via Narita International Airport (NRT) and Haneda Airport (HND). Direct flights from major cities make it a convenient destination for travelers.",
      },
      {
        "icon": Icons.wb_sunny_rounded,
        "title": "Best Time To Visit:",
        "description":
            "Tokyo is a year-round destination, but spring (March to May) and autumn (September to November) are the best times to enjoy pleasant weather and stunning cherry blossoms or colorful foliage.",
      },
      {
        "icon": Icons.place_rounded,
        "title": "Must-See Attractions:",
        "description":
            "Explore Tokyo's top attractions, including the historic Senso-ji Temple, bustling Shibuya Crossing, the Imperial Palace, and the futuristic Tokyo Skytree.",
      },
      {
        "icon": Icons.restaurant_rounded,
        "title": "Local Cuisine:",
        "description":
            "Indulge in mouthwatering dishes like sushi, ramen, tempura, and okonomiyaki. Don't forget to try street food in places like Tsukiji Fish Market.",
      },
      {
        "icon": Icons.hiking_rounded,
        "title": "Activities and Experiences:",
        "description":
            "Dive into Tokyo's culture with activities like tea ceremonies, sumo wrestling matches, and exploring traditional neighborhoods like Asakusa.",
      },
      {
        "icon": Icons.hotel_rounded,
        "title": "Accommodations:",
        "description":
            "Tokyo offers a range of accommodations, from luxury hotels in Ginza to budget-friendly hostels in Asakusa. Choose a location that suits your travel style.",
      },
      {
        "icon": Icons.train_rounded,
        "title": "Transportation:",
        "description":
            "Tokyo boasts an efficient public transportation system, including the subway and JR trains. Consider purchasing a Japan Rail Pass for convenient travel within the city and beyond.",
      },
      {
        "icon": Icons.health_and_safety_rounded,
        "title": "Safety and Health Tips:",
        "description":
            "Tokyo is known for its safety, but it's essential to stay vigilant. Ensure you have travel insurance, know emergency numbers, and respect local customs.",
      },
      {
        "icon": Icons.translate_rounded,
        "title": "Local Language:",
        "description":
            "Learning a few Japanese phrases can enhance your experience. Start with common greetings like 'Konnichiwa' (Hello) and 'Arigatou gozaimasu' (Thank you).",
      },
      {
        "icon": Icons.payments_rounded,
        "title": "Currency:",
        "description":
            "Japan's currency is the yen (¥). Credit cards are widely accepted, but it's a good idea to have some cash on hand for small purchases.",
      },
      {
        "icon": Icons.assignment_rounded,
        "title": "Visa and Entry Requirements:",
        "description":
            "Check the visa requirements for your nationality before traveling to Japan. Many countries have visa-free access for short stays.",
      },
    ];

    final galleryImages = [
      "https://images.unsplash.com/photo-1542051841857-5f90071e7989",
      "https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e",
      "https://images.unsplash.com/photo-1492571350019-22de08371fd3",
    ];

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
              context.push(TripWizardScreen.routeName, extra: place);
            },
          ),
        ),
      ),

      body: CustomScrollView(
        slivers: [
          /// APP BAR IMAGE
          SliverAppBar(
            expandedHeight: 340.h,
            pinned: true,
            backgroundColor: context.colors.surface,

            leading: Padding(
              padding: EdgeInsets.only(left: 14.w, top: 6.h),
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
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
                  final mapUrl = place.googleMapsUrl ?? "https://maps.google.com/?q=${Uri.encodeComponent(place.name)}";
                  final shareText = "Explore ${place.name} in ${place.address} on WanderSouls! 🌍✈️\nLocation Link: $mapUrl";
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
                    tag: place.placeId,
                    child: Image.network(
                      "https://images.unsplash.com/photo-1545569341-9eb8b30979d9?q=80&w=1200",
                      fit: BoxFit.cover,
                    ),
                  ),
                  // Gradient overlay for better text readability
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
                    place.name,
                    style: context.text.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: context.colors.onSurface,
                      letterSpacing: -0.3,
                    ),
                  ),

                  8.h.verticalSpace,

                  /// COUNTRY
                  Row(
                    children: [
                      Text("📍", style: TextStyle(fontSize: 16.sp)),
                      8.w.horizontalSpace,
                      Text(
                        place.address.isNotEmpty ? place.address : "Destination",
                        style: context.text.bodyMedium?.copyWith(
                          color: context.colors.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  20.h.verticalSpace,

                  /// DESCRIPTION
                  Text(
                    place.description.isNotEmpty
                        ? place.description
                        : "Discover the vibrant highlights of ${place.name}, where modernity meets tradition in perfect harmony. From stunning views to historical landmarks, ${place.name} offers a memorable blend of experiences.",
                    style: context.text.bodyLarge?.copyWith(
                      color: context.colors.onSurfaceVariant,
                      height: 1.6,
                    ),
                  ),

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
                          ),
                        );
                      },
                    ),
                  ),

                  28.h.verticalSpace,

                  /// SECTIONS with icons
                  ...sections.map(
                    (section) => Padding(
                      padding: EdgeInsets.only(bottom: 20.h),
                      child: Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: context.mutedBackground,
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: context.borderColor.withAlpha(20),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8.w),
                                  decoration: BoxDecoration(
                                    color: context.primaryTint,
                                    borderRadius: BorderRadius.circular(10.r),
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
                                    style: context.text.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: context.colors.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            12.h.verticalSpace,

                            Text(
                              section["description"] as String,
                              style: context.text.bodyMedium?.copyWith(
                                height: 1.6,
                                color: context.colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
