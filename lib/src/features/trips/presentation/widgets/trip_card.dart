import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wonder_souls/src/features/trips/model/trip.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_text.dart';

class TripCard extends StatelessWidget {
  const TripCard({super.key, required this.trip});
  final TripData trip;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: context.borderColor.withAlpha(20), width: 1),
        boxShadow: [
          BoxShadow(
            color: context.softShadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image with gradient overlay
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 20 / 9,
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(20.r),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: trip.imageUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      color: context.shimmerBase,
                      child: Icon(
                        Icons.image_rounded,
                        size: 40,
                        color: context.onSurfaceVariant.withAlpha(60),
                      ),
                    ),
                  ),
                ),
              ),
              // Gradient overlay
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(20.r),
                  ),
                  child: DecoratedBox(
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
                ),
              ),
            ],
          ),

          // Trip details
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              trip.name,
                              overflow: TextOverflow.ellipsis,
                              style: context.text.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Text(trip.flag, style: TextStyle(fontSize: 18.sp)),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        color: context.mutedBackground,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        Icons.more_horiz_rounded,
                        color: context.onSurfaceVariant,
                        size: 20.sp,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  '${trip.dateRange} · ${trip.tripType} · ${trip.category}',
                  style: context.text.bodySmall?.copyWith(
                    color: context.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
