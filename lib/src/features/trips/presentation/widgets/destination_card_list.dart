import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wonder_souls/src/config/core/injector/injector.dart';
import 'package:wonder_souls/src/config/core/services/google_places_new_service.dart';
import 'package:wonder_souls/src/config/utils/common_widgets/size.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_text.dart';
import 'package:wonder_souls/src/config/core/model/place_model.dart';
import '../../../../config/utils/common_widgets/saved_icon.dart';

class DestinationCardList extends StatefulWidget {
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
  State<DestinationCardList> createState() => _DestinationCardListState();
}

class _DestinationCardListState extends State<DestinationCardList> {
  static final Map<String, String> _googlePlacesCache = {};
  String? _resolvedImageUrl;

  @override
  void initState() {
    super.initState();
    _resolveImage();
  }

  @override
  void didUpdateWidget(covariant DestinationCardList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.place.placeId != widget.place.placeId ||
        oldWidget.city != widget.city) {
      _resolveImage();
    }
  }

  void _resolveImage() {
    final originalUrl = widget.imageUrl;
    if (originalUrl.contains("places.googleapis.com") ||
        originalUrl.contains("maps.googleapis.com")) {
      _resolvedImageUrl = originalUrl;
      return;
    }

    final key = widget.place.placeId.isNotEmpty
        ? widget.place.placeId
        : widget.city.toLowerCase();

    if (_googlePlacesCache.containsKey(key)) {
      _resolvedImageUrl = _googlePlacesCache[key];
      return;
    }

    _resolvedImageUrl = originalUrl;
    _fetchGooglePlacesPhoto();
  }

  Future<void> _fetchGooglePlacesPhoto() async {
    try {
      final placesService = sl.isRegistered<GooglePlacesNewService>()
          ? sl<GooglePlacesNewService>()
          : GooglePlacesNewService();

      String? placeId = widget.place.placeId;
      if (placeId.isEmpty) {
        placeId = await placesService.searchPlaceId("${widget.city}, ${widget.country}");
      }

      if (placeId != null && placeId.isNotEmpty) {
        final details = await placesService.getPlaceDetails(placeId);
        final photos = details?["photos"] as List?;
        if (photos != null && photos.isNotEmpty) {
          final photoName = photos.first["name"];
          if (photoName != null) {
            final uri = await placesService.getPhotoUri(photoName);
            if (uri != null && uri.isNotEmpty) {
              final key = widget.place.placeId.isNotEmpty
                  ? widget.place.placeId
                  : widget.city.toLowerCase();
              _googlePlacesCache[key] = uri;
              if (mounted) {
                setState(() {
                  _resolvedImageUrl = uri;
                });
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint("DestinationCardList: error resolving photo for ${widget.city}: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayImageUrl = _resolvedImageUrl ?? widget.imageUrl;

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
              Positioned(top: 12, right: 12, child: SavedIcon(place: widget.place)),
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
                        widget.city,
                        style: context.text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      6.h.height,
                      Row(
                        children: [
                          Text(widget.flagEmoji, style: TextStyle(fontSize: 16.sp)),
                          SizedBox(width: 6.w),
                          Expanded(
                            child: Text(
                              widget.country,
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
