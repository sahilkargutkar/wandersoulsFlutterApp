import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:wonder_souls/src/config/core/model/place_model.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';
import 'package:wonder_souls/src/features/trips/presentation/screens/trip_wizard/trip_wizard_screen.dart';

class AiItineraryBanner extends StatelessWidget {
  const AiItineraryBanner({super.key});

  void _navigateToAiWizard(BuildContext context) {
    final defaultPlace = PlaceModel(
      placeId: "ai_custom_trip",
      name: "Thailand",
      description: "AI Generated Itinerary for Thailand",
      address: "Thailand",
      types: const ["travel", "tourism"],
    );
    context.push(TripWizardScreen.routeName, extra: defaultPlace);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Container(
      width: double.infinity,
      height: 130.h,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: Stack(
          children: [
            // Background Image on the right
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: 170.w,
              child: CachedNetworkImage(
                imageUrl:
                    "https://images.unsplash.com/photo-1506665531195-3566af2b4dfa?w=800&q=80",
                fit: BoxFit.cover,
                alignment: Alignment.centerRight,
              ),
            ),

            // Smooth linear gradient fading the image into the card background
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    stops: const [0.0, 0.52, 0.82, 1.0],
                    colors: isDark
                        ? [
                            const Color(0xFF1E293B),
                            const Color(0xFF1E293B),
                            const Color(0xFF1E293B).withValues(alpha: 0.4),
                            Colors.transparent,
                          ]
                        : [
                            Colors.white,
                            Colors.white,
                            Colors.white.withValues(alpha: 0.3),
                            Colors.transparent,
                          ],
                  ),
                ),
              ),
            ),

            // Content Left
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Title
                  Text(
                    "Plan your trip with AI",
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: 3.h),

                  // Subtitle
                  Text(
                    "Personalized itineraries in seconds",
                    style: TextStyle(
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // Compact Action Button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _navigateToAiWizard(context),
                      borderRadius: BorderRadius.circular(20.r),
                      child: Ink(
                        padding: EdgeInsets.symmetric(
                          horizontal: 14.w,
                          vertical: 7.h,
                        ),
                        decoration: BoxDecoration(
                          color: context.primary,
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_awesome_rounded,
                              color: Colors.white,
                              size: 13.sp,
                            ),
                            SizedBox(width: 5.w),
                            Text(
                              "Create Itinerary",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11.5.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 12.sp,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
