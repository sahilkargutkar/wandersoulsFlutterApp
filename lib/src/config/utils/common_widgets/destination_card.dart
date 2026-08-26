import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wonder_souls/src/config/core/injector/injector.dart';
import 'package:wonder_souls/src/config/core/services/google_places_new_service.dart';
import 'package:wonder_souls/src/config/utils/common_widgets/saved_icon.dart';
import 'package:wonder_souls/src/config/utils/common_widgets/size.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_text.dart';
import 'package:wonder_souls/src/config/core/model/place_model.dart';

class DestinationCard extends StatefulWidget {
  final String imageUrl;
  final String city;
  final String country;
  final String flagEmoji;
  final double? cardWidth;
  final PlaceModel place;

  const DestinationCard({
    super.key,
    required this.imageUrl,
    required this.city,
    required this.country,
    required this.flagEmoji,
    required this.place,
    this.cardWidth,
  });

  @override
  State<DestinationCard> createState() => _DestinationCardState();
}

class _DestinationCardState extends State<DestinationCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  static final Map<String, String> _googlePlacesCache = {};
  String? _resolvedImageUrl;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _resolveImage();
  }

  @override
  void didUpdateWidget(covariant DestinationCard oldWidget) {
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
      debugPrint("DestinationCard: error resolving photo for ${widget.city}: $e");
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = context.text;
    final screenWidth = MediaQuery.of(context).size.width;

    final responsiveWidth =
        widget.cardWidth ??
        (screenWidth < 360
            ? screenWidth * 0.75
            : screenWidth < 400
            ? screenWidth * 0.72
            : screenWidth < 600
            ? screenWidth * 0.68
            : 300.w);

    final displayImageUrl = _resolvedImageUrl ?? widget.imageUrl;

    return Listener(
      onPointerDown: (_) => _controller.forward(),
      onPointerUp: (_) => _controller.reverse(),
      onPointerCancel: (_) => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) =>
            Transform.scale(scale: _scaleAnimation.value, child: child),
        child: SizedBox(
          width: responsiveWidth,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20.r),
            child: Stack(
              fit: StackFit.passthrough,
              children: [
                /// IMAGE
                AspectRatio(
                  aspectRatio: 3 / 4,
                  child: CachedNetworkImage(
                    imageUrl: displayImageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(color: colors.onSurface.withAlpha(20)),
                    errorWidget: (_, __, ___) => Container(
                      color: colors.onSurface.withAlpha(20),
                      child: Icon(
                        Icons.image_rounded,
                        size: 42.sp,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),

                /// GRADIENT OVERLAY
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.1),
                          Colors.black.withValues(alpha: 0.8),
                        ],
                        stops: const [0.5, 0.7, 1.0],
                      ),
                    ),
                  ),
                ),

                /// SAVE BUTTON
                Positioned(
                  top: 12.h,
                  right: 12.w,
                  child: SavedIcon(place: widget.place),
                ),

                /// DETAILS
                Positioned(
                  bottom: 12.h,
                  left: 12.w,
                  right: 12.w,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Text(
                              widget.city,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 18.sp,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.white,
                            size: 14.sp,
                          ),
                        ],
                      ),
                      4.h.height,
                      Row(
                        children: [
                          Text(
                            widget.flagEmoji,
                            style: TextStyle(fontSize: 14.sp),
                          ),
                          6.w.width,
                          Expanded(
                            child: Text(
                              widget.country,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodySmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
