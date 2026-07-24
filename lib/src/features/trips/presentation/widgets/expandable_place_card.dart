import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wonder_souls/src/features/trips/model/trip.dart';
import 'package:wonder_souls/src/config/utils/common_widgets/size.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_text.dart';

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
            padding: EdgeInsets.only(top: 14.h),
            child: Icon(
              widget.icon,
              size: 22.sp,
              color: context.colors.onSurfaceVariant,
            ),
          ),

          12.w.width,

          /// RIGHT CARD
          Expanded(
            child: Card(
              elevation: 4,
              shadowColor: Colors.black.withAlpha(20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
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
                              style: context.text.labelMedium,
                            ),
                          ),
                          AnimatedRotation(
                            turns: isExpanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 250),
                            child: const Icon(Icons.expand_more),
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
            color: Colors.grey[300],
            child: Icon(Icons.image, size: 48.sp),
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
                  Icon(Icons.star, size: 16.sp, color: context.colors.primary),
                  4.w.width,
                  Text('${place?.rating}', style: context.text.bodyMedium),
                  4.w.width,
                  Text(
                    '(${place?.reviews} reviews)',
                    style: context.text.labelSmall,
                  ),
                ],
              ),

              12.h.height,

              /// TIME
              Row(
                children: [
                  Icon(Icons.access_time, size: 16.sp),
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
                  Icon(Icons.attach_money, size: 16.sp),
                  8.w.width,
                  Text(
                    '\$${place?.price.toStringAsFixed(2)}',
                    style: context.text.bodyMedium,
                  ),
                ],
              ),

              12.h.height,

              /// MAP LINK
              InkWell(
                onTap: () {},
                child: Row(
                  children: [
                    Icon(Icons.map, size: 16.sp, color: context.colors.primary),
                    8.w.width,
                    Text(
                      'View on Google Maps',
                      style: TextStyle(
                        color: context.colors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
