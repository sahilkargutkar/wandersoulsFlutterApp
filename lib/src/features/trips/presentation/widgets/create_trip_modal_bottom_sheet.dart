import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:wonder_souls/src/config/core/model/place_model.dart';
import 'package:wonder_souls/src/features/trips/presentation/screens/list_destination.dart';
import 'package:wonder_souls/src/features/trips/presentation/screens/list_public_trips.dart';
import 'package:wonder_souls/src/features/trips/presentation/screens/trip_wizard/trip_wizard_screen.dart';

/// Displays the floating speed-dial style popup for creating a trip.
void showCreateTripModal(
  BuildContext context, {
  void Function(int tabIndex)? onSelectTab,
}) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.black.withValues(alpha: 0.45),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (dialogContext, anim1, anim2) {
      return CreateTripOverlay(onSelectTab: onSelectTab);
    },
    transitionBuilder: (dialogContext, anim1, anim2, child) {
      final curvedAnim = CurvedAnimation(
        parent: anim1,
        curve: Curves.easeOutCubic,
      );

      return FadeTransition(
        opacity: curvedAnim,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.08),
            end: Offset.zero,
          ).animate(curvedAnim),
          child: child,
        ),
      );
    },
  );
}

class CreateTripOverlay extends StatelessWidget {
  final void Function(int tabIndex)? onSelectTab;

  const CreateTripOverlay({
    super.key,
    this.onSelectTab,
  });

  void _onAiPlannerTap(BuildContext context) {
    Navigator.pop(context);
    final defaultPlace = PlaceModel(
      placeId: "ai_custom_trip",
      name: "Custom Trip",
      description: "AI Generated Itinerary",
      address: "Anywhere in the World",
      types: const ["travel", "tourism"],
    );
    context.push(TripWizardScreen.routeName, extra: defaultPlace);
  }

  void _onBuildOwnTripTap(BuildContext context) {
    Navigator.pop(context);
    if (onSelectTab != null) {
      onSelectTab!(1); // Switch to Explore/Destinations Tab
    } else {
      context.push(ListDestination.routeName);
    }
  }

  void _onCommunityTripTap(BuildContext context) {
    Navigator.pop(context);
    context.push(ListPublicTripsScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: SizedBox.expand(
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // Floating Options & Close Button column aligned to bottom center
                Positioned(
                  bottom: 12.h,
                  child: GestureDetector(
                    onTap: () {}, // Prevent taps inside from closing dialog
                    behavior: HitTestBehavior.deferToChild,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Option 1: AI Trip Planner (Top Pill)
                        _buildPillOption(
                          context: context,
                          icon: Icons.auto_awesome_rounded,
                          iconColor: const Color(0xFF9333EA),
                          iconBgColor: const Color(0xFFF3E8FF),
                          pillBgColor: const Color(0xFFFAF5FF),
                          title: "AI Trip Planner",
                          titleColor: const Color(0xFF4C1D95),
                          subtitle: "Create with AI",
                          subtitleColor: const Color(0xFF7C3AED),
                          onTap: () => _onAiPlannerTap(context),
                        ),
                        SizedBox(height: 12.h),

                        // Option 2: Build My Own Trip (Middle Pill)
                        _buildPillOption(
                          context: context,
                          icon: Icons.edit_rounded,
                          iconColor: const Color(0xFF0D9488),
                          iconBgColor: const Color(0xFFCCFBF1),
                          pillBgColor: const Color(0xFFF0FDF4),
                          title: "Build My Own Trip",
                          titleColor: const Color(0xFF115E59),
                          subtitle: "Plan manually",
                          subtitleColor: const Color(0xFF0F766E),
                          onTap: () => _onBuildOwnTripTap(context),
                        ),
                        SizedBox(height: 12.h),

                        // Option 3: From a Community Trip (Bottom Pill)
                        _buildPillOption(
                          context: context,
                          icon: Icons.people_alt_rounded,
                          iconColor: const Color(0xFFEA580C),
                          iconBgColor: const Color(0xFFFFEDD5),
                          pillBgColor: const Color(0xFFFFFBEB),
                          title: "From a Community Trip",
                          titleColor: const Color(0xFF9A3412),
                          subtitle: "Customize a traveler's plan",
                          subtitleColor: const Color(0xFFC2410C),
                          onTap: () => _onCommunityTripTap(context),
                        ),
                        SizedBox(height: 20.h),

                        // Bottom Center 'X' (Close) Button
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 50.w,
                            height: 50.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF9333EA),
                              border: Border.all(
                                color: Colors.white,
                                width: 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF9333EA).withValues(alpha: 0.45),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 26.sp,
                            ),
                          ),
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
    );
  }

  Widget _buildPillOption({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required Color pillBgColor,
    required String title,
    required Color titleColor,
    required String subtitle,
    required Color subtitleColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30.r),
        child: Container(
          constraints: BoxConstraints(
            minWidth: 230.w,
            maxWidth: 270.w,
          ),
          padding: EdgeInsets.fromLTRB(8.w, 7.h, 20.w, 7.h),
          decoration: BoxDecoration(
            color: pillBgColor,
            borderRadius: BorderRadius.circular(30.r),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.9),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon Circle
              Container(
                width: 38.w,
                height: 38.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconBgColor,
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),

              // Title and Subtitle
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 1.5.h),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 10.5.sp,
                        fontWeight: FontWeight.w500,
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
