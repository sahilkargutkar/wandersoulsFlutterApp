import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wonder_souls/src/config/utils/trip_image_helper.dart';
import 'package:wonder_souls/src/features/trips/model/trip.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_text.dart';

class TripCard extends StatefulWidget {
  const TripCard({super.key, required this.trip});
  final TripData trip;

  @override
  State<TripCard> createState() => _TripCardState();
}

class _TripCardState extends State<TripCard> {
  String? _resolvedImageUrl;

  @override
  void initState() {
    super.initState();
    _resolveImage();
  }

  @override
  void didUpdateWidget(covariant TripCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trip.id != widget.trip.id ||
        oldWidget.trip.imageUrl != widget.trip.imageUrl ||
        oldWidget.trip.mainDestination != widget.trip.mainDestination) {
      _resolveImage();
    }
  }

  void _resolveImage() {
    final originalUrl = widget.trip.imageUrl;
    // If already a Google Places URL, use it directly
    if (originalUrl.contains("places.googleapis.com") ||
        originalUrl.contains("maps.googleapis.com")) {
      _resolvedImageUrl = originalUrl;
      return;
    }

    final destKey = widget.trip.mainDestination.trim().isNotEmpty
        ? widget.trip.mainDestination.trim()
        : widget.trip.name.trim();

    if (destKey.isEmpty) {
      _resolvedImageUrl = originalUrl;
      return;
    }

    final cached = TripImageHelper.getCachedPhoto(destKey);
    if (cached != null) {
      _resolvedImageUrl = cached;
      return;
    }

    _resolvedImageUrl = originalUrl;
    TripImageHelper.resolvePhoto(destKey).then((uri) {
      if (uri != null && mounted) {
        setState(() {
          _resolvedImageUrl = uri;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final displayImageUrl = _resolvedImageUrl ?? widget.trip.imageUrl;

    return Container(
      margin: EdgeInsets.only(bottom: 20.h),
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image container with border & shadow
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: context.borderColor.withAlpha(20),
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(19.r),
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 20 / 9,
                    child: CachedNetworkImage(
                      imageUrl: displayImageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: context.shimmerBase,
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: context.primary.withAlpha(100),
                          ),
                        ),
                      ),
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
                  // Gradient overlay
                  Positioned.fill(
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
                ],
              ),
            ),
          ),

          // Trip details (outside the card border)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 12.h),
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
                              widget.trip.name,
                              overflow: TextOverflow.ellipsis,
                              style: context.text.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Text(widget.trip.flag, style: TextStyle(fontSize: 18.sp)),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(6.w),
                      decoration: BoxDecoration(
                        color: context.mutedBackground,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        Icons.more_vert_rounded,
                        color: context.onSurfaceVariant,
                        size: 20.sp,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                Text(
                  '${widget.trip.dateRange} · ${widget.trip.tripType} · ${widget.trip.category}',
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
