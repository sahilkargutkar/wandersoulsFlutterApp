import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wonder_souls/src/features/trips/model/trip.dart';
import 'package:wonder_souls/src/config/utils/common_widgets/size.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_text.dart';
import 'package:wonder_souls/src/config/utils/common_widgets/animated_press.dart';

class ExpandablePlaceCard extends StatefulWidget {
  final Place? place;
  final IconData icon;

  const ExpandablePlaceCard({
    super.key,
    required this.place,
    required this.icon,
  });

  @override
  State<ExpandablePlaceCard> createState() => _ExpandablePlaceCardState();
}

class _ExpandablePlaceCardState extends State<ExpandablePlaceCard> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final place = widget.place;

    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// LEFT ICON
          Container(
            width: 36.w,
            alignment: Alignment.topCenter,
            padding: EdgeInsets.only(top: 16.h),
            child: Container(
              padding: EdgeInsets.all(6.w),
              decoration: BoxDecoration(
                color: context.primaryTint,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(widget.icon, size: 18.sp, color: context.primary),
            ),
          ),

          12.w.width,

          /// RIGHT CARD
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: context.surface,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: context.borderColor.withAlpha(30),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: context.softShadow,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  /// HEADER (Always visible)
                  InkWell(
                    onTap: () {
                      setState(() => isExpanded = !isExpanded);
                    },
                    child: Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              place?.name ?? "",
                              style: context.text.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          AnimatedRotation(
                            turns: isExpanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 250),
                            child: Icon(
                              Icons.expand_more_rounded,
                              color: context.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  /// EXPANDED CONTENT
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 300),
                    crossFadeState: isExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    firstChild: const SizedBox.shrink(),
                    secondChild: _ExpandedContent(place: place),
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

class _ExpandedContent extends StatelessWidget {
  final Place? place;

  const _ExpandedContent({required this.place});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// IMAGE
        CachedNetworkImage(
          imageUrl: place?.imageUrl ?? "",
          height: 160.h,
          width: double.infinity,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => Container(
            height: 160.h,
            color: context.shimmerBase,
            child: Icon(
              Icons.image_rounded,
              size: 48.sp,
              color: context.onSurfaceVariant.withAlpha(60),
            ),
          ),
        ),

        Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// RATING
              Row(
                children: [
                  Icon(
                    Icons.star_rounded,
                    size: 16.sp,
                    color: const Color(0xFFF59E0B),
                  ),
                  4.w.width,
                  Text(
                    '${place?.rating}',
                    style: context.text.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  4.w.width,
                  Text(
                    '(${place?.reviews} reviews)',
                    style: context.text.bodySmall?.copyWith(
                      color: context.onSurfaceVariant,
                    ),
                  ),
                ],
              ),

              12.h.height,

              /// TIME
              Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 16.sp,
                    color: context.onSurfaceVariant,
                  ),
                  8.w.width,
                  Text(
                    '${place?.openTime} - ${place?.closeTime}',
                    style: context.text.bodyMedium,
                  ),
                ],
              ),

              8.h.height,

              /// PRICE
              Row(
                children: [
                  Icon(
                    Icons.attach_money_rounded,
                    size: 16.sp,
                    color: context.onSurfaceVariant,
                  ),
                  8.w.width,
                  Text(
                    '\$${place?.price.toStringAsFixed(2)}',
                    style: context.text.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.primary,
                    ),
                  ),
                ],
              ),

              14.h.height,

              /// MAP LINK
              AnimatedPress(
                onTap: () {},
                scaleFactor: 0.94,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: context.primaryTint,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.map_rounded,
                        size: 16.sp,
                        color: context.primary,
                      ),
                      8.w.width,
                      Text(
                        'View on Google Maps',
                        style: context.text.bodySmall?.copyWith(
                          color: context.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
