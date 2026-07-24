import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wonder_souls/src/config/utils/common_widgets/circular_icon.dart';
import 'package:wonder_souls/src/config/utils/common_widgets/size.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_text.dart';
import 'package:wonder_souls/src/features/trips/model/destination_guide.dart';
import 'package:wonder_souls/src/features/trips/presentation/screens/trip_wizard_screen.dart';

class DestinationExplorerScreen extends StatelessWidget {
  final Map<String, String> destination;

  const DestinationExplorerScreen({
    super.key,
    required this.destination,
  });

  static const String routeName = "/DestinationExplorerScreen";

  @override
  Widget build(BuildContext context) {
    final cityName = destination['city'] ?? 'Tokyo, Tokyo';
    final guide = DestinationGuide.getGuideForCity(cityName);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Collapsing Image Header with Back button
          SliverAppBar(
            expandedHeight: 250.h,
            pinned: true,
            backgroundColor: context.surface,
            elevation: 0,
            leading: Padding(
              padding: EdgeInsets.only(left: 12.w),
              child: Center(
                child: CircularIcon(
                  icon: Icon(
                    Icons.arrow_back_ios_new,
                    size: 18.sp,
                    color: context.onSurface,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: CachedNetworkImage(
                imageUrl: guide.imageUrl,
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Scrollable Body Content
          SliverToBoxAdapter(
            child: Container(
              color: context.surface,
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    guide.city,
                    style: context.text.titleLarge?.copyWith(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: context.onSurface,
                    ),
                  ),
                  8.h.height,

                  // Location (Flag & Country)
                  Row(
                    children: [
                      Text(
                        guide.flagEmoji,
                        style: TextStyle(fontSize: 20.sp),
                      ),
                      8.w.width,
                      Text(
                        guide.country,
                        style: context.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  20.h.height,

                  // Description
                  Text(
                    guide.description,
                    style: context.bodyMedium?.copyWith(
                      height: 1.5,
                      color: Colors.grey[800],
                    ),
                  ),
                  24.h.height,

                  // Gallery Section
                  Text(
                    'Gallery',
                    style: context.text.titleLarge?.copyWith(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: context.onSurface,
                    ),
                  ),
                  12.h.height,

                  // Gallery Images
                  Row(
                    children: guide.gallery.map((url) {
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4.w),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12.r),
                              child: CachedNetworkImage(
                                imageUrl: url,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => Container(
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.image, color: Colors.grey),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  28.h.height,

                  // Detail Sections
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: guide.sections.map((entry) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: 24.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.key,
                              style: context.text.titleLarge?.copyWith(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: context.onSurface,
                              ),
                            ),
                            8.h.height,
                            Text(
                              entry.value,
                              style: context.bodyMedium?.copyWith(
                                color: Colors.grey[700],
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      // Persistent Premium Bottom Button
      bottomNavigationBar: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: context.surface,
          border: Border(
            top: BorderSide(color: Colors.grey[200]!, width: 1),
          ),
        ),
        child: SafeArea(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: context.primary,
              foregroundColor: Colors.white,
              minimumSize: Size(double.infinity, 50.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25.r),
              ),
              elevation: 0,
            ),
            onPressed: () {
              Navigator.pushNamed(
                context,
                TripWizardScreen.routeName,
                arguments: destination,
              );
            },
            child: Text(
              'Start a Trip',
              style: context.text.titleLarge?.copyWith(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
