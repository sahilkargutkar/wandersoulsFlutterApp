import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wonder_souls/src/config/utils/common_widgets/size.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_text.dart';
import 'package:wonder_souls/src/config/core/model/place_model.dart';

import '../../../../config/utils/common_widgets/saved_icon.dart';

class DestinationCardList extends StatelessWidget {
  final String imageUrl;
  final String city;
  final String country;
  final String flagEmoji;
  final PlaceModel place;

  const DestinationCardList({
    super.key,
    required this.imageUrl,
    required this.city,
    required this.country,
    required this.flagEmoji,
    required this.place,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // IMAGE
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 20 / 11,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    color: context.shimmerBase,
                    child: Icon(
                      Icons.image_rounded,
                      color: context.onSurfaceVariant.withAlpha(60),
                      size: 40,
                    ),
                  ),
                ),
              ),
              // Gradient overlay
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withAlpha(20)],
                    ),
                  ),
                ),
              ),
              Positioned(top: 12, right: 12, child: SavedIcon(place: place)),
            ],
          ),

          Padding(
            padding: EdgeInsets.all(14.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        city,
                        style: context.text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      6.h.height,
                      Row(
                        children: [
                          Text(flagEmoji, style: TextStyle(fontSize: 16.sp)),
                          SizedBox(width: 6.w),
                          Expanded(
                            child: Text(
                              country,
                              style: context.text.bodyMedium?.copyWith(
                                color: context.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
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
          ),
        ],
      ),
    );
  }
}
