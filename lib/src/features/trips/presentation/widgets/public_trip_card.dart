import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_text.dart';
import 'package:wonder_souls/src/config/utils/trip_image_helper.dart';
import 'package:wonder_souls/src/features/trips/model/trip.dart';
import 'package:wonder_souls/src/features/trips/presentation/screens/trip_details_screen.dart';

class PublicTripCard extends StatelessWidget {
  final TripData trip;
  final double? cardWidth;

  const PublicTripCard({
    super.key,
    required this.trip,
    this.cardWidth,
  });

  @override
  Widget build(BuildContext context) {
    final width = cardWidth ?? 240.w;
    final displayImageUrl = TripImageHelper.getDisplayImageUrl(trip);

    return InkWell(
      onTap: () {
        final tripToPass = trip.copyWith(imageUrl: displayImageUrl);
        context.push(TripDetailsScreen.routeName, extra: tripToPass);
      },
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: context.borderColor.withAlpha(40),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: context.softShadow,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with Badges
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(19.r)),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: displayImageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: context.shimmerBase,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Image.network(
                        TripData.getTripImage(trip.mainDestination),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: context.shimmerBase,
                          child: Icon(
                            Icons.public_rounded,
                            size: 40.sp,
                            color: context.onSurfaceVariant.withAlpha(60),
                          ),
                        ),
                      ),
                    ),
                    // Gradient
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withAlpha(60),
                            Colors.transparent,
                            Colors.black.withAlpha(90),
                          ],
                        ),
                      ),
                    ),
                    // Top Left Public Badge
                    Positioned(
                      top: 10.h,
                      left: 10.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              trip.flag,
                              style: TextStyle(fontSize: 12.sp),
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              trip.mainDestination,
                              style: context.text.labelSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 10.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Top Right Category/Budget Badge
                    Positioned(
                      top: 10.h,
                      right: 10.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: context.primary.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Text(
                          trip.category,
                          style: context.text.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 10.sp,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Content Details
            Padding(
              padding: EdgeInsets.all(12.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trip.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.sp,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 12.sp,
                        color: context.onSurfaceVariant,
                      ),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: Text(
                          trip.dateRange,
                          style: context.text.labelSmall?.copyWith(
                            color: context.onSurfaceVariant,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (trip.totalBudget > 0) ...[
                        Text(
                          "${trip.currency} ${trip.totalBudget.toStringAsFixed(0)}",
                          style: context.text.labelSmall?.copyWith(
                            color: context.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 11.sp,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (trip.travelTastes.isNotEmpty) ...[
                    SizedBox(height: 8.h),
                    Wrap(
                      spacing: 4.w,
                      runSpacing: 4.h,
                      children: trip.travelTastes.take(2).map((t) {
                        return Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: context.mutedBackground,
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            "#$t",
                            style: context.text.labelSmall?.copyWith(
                              fontSize: 9.sp,
                              color: context.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
