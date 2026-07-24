import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wonder_souls/src/config/utils/common_widgets/size.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_text.dart';

import '../../../../config/utils/common_widgets/saved_icon.dart';

class DestinationCardList extends StatelessWidget {
  final String imageUrl;
  final String city;
  final String country;
  final String flagEmoji;

  const DestinationCardList({
    super.key,
    required this.imageUrl,
    required this.city,
    required this.country,
    required this.flagEmoji, // default for Home
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = context.text;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      shadowColor: colors.onSurface.withAlpha(25),
      color: context.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // IMAGE
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 20 / 11,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                    bottom: Radius.circular(16),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    // height: imageHeight,
                    width: double.infinity, // ✅ LIMIT decoded image size

                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      // height: imageHeight,
                      color: colors.surface,
                      child: Icon(
                        Icons.image,
                        color: colors.surface.withAlpha(20),
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(top: 12, right: 12, child: SavedIcon()),
            ],
          ),

          Padding(
            padding: EdgeInsets.all(12.sp),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        city,
                        style: context.text.titleLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      6.h.height,
                      Row(
                        children: [
                          Text(flagEmoji, style: TextStyle(fontSize: 18.sp)),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(country, style: textTheme.bodyLarge),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.more_vert, color: context.onSurface, size: 20.sp),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
