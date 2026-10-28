import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:wonder_souls/src/config/core/services/route_direction_service.dart';
import 'package:wonder_souls/src/features/trips/model/trip_activity_model.dart';

const Map<String, LatLng> _kKnownPlaceCoords = {
  // Shillong & Meghalaya
  'umiam lake': LatLng(25.6542, 91.8953),
  'elephant falls': LatLng(25.5358, 91.8214),
  "ward's lake": LatLng(25.5768, 91.8845),
  'wards lake': LatLng(25.5768, 91.8845),
  'shillong peak': LatLng(25.5386, 91.8542),
  'don bosco museum': LatLng(25.6033, 91.8988),
  'laitlum canyons': LatLng(25.4485, 91.9056),
  'police bazar': LatLng(25.5776, 91.8828),
  'cherrapunji': LatLng(25.2702, 91.7323),
  'nohkalikai falls': LatLng(25.2757, 91.7082),
  'dawki': LatLng(25.1842, 92.0167),
  // Tokyo & Japan
  'senso-ji': LatLng(35.7148, 139.7967),
  'sensoji': LatLng(35.7148, 139.7967),
  'tokyo skytree': LatLng(35.7100, 139.8107),
  'shibuya crossing': LatLng(35.6595, 139.7005),
  'meiji shrine': LatLng(35.6764, 139.6993),
  'shinjuku gyoen': LatLng(35.6852, 139.7101),
  'akihabara': LatLng(35.6984, 139.7731),
};

const Map<String, LatLng> _kCityCenters = {
  'shillong': LatLng(25.5788, 91.8933),
  'tokyo': LatLng(35.6762, 139.6503),
  'paris': LatLng(48.8566, 2.3522),
  'london': LatLng(51.5074, -0.1278),
  'new york': LatLng(40.7128, -74.0060),
  'rome': LatLng(41.9028, 12.4964),
  'bangkok': LatLng(13.7563, 100.5018),
  'singapore': LatLng(1.3521, 103.8198),
  'dubai': LatLng(25.2048, 55.2708),
  'muscat': LatLng(23.5880, 58.3829),
  'bali': LatLng(-8.4095, 115.1889),
};

/// Clean, minimal light theme with pale roads, soft geography, and readable labels
const String _kMinimalLightMapStyle = '''[
  {
    "elementType": "geometry",
    "stylers": [{"color": "#f8fafc"}]
  },
  {
    "elementType": "labels.icon",
    "stylers": [{"visibility": "on"}]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#334155"}]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [{"color": "#ffffff"}, {"weight": 3.0}]
  },
  {
    "featureType": "administrative",
    "elementType": "geometry",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "administrative.country",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#cbd5e1"}, {"visibility": "on"}, {"weight": 1.0}]
  },
  {
    "featureType": "administrative.locality",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#0f172a"}, {"weight": 1.5}]
  },
  {
    "featureType": "landscape.man_made",
    "elementType": "geometry.fill",
    "stylers": [{"color": "#f1f5f9"}]
  },
  {
    "featureType": "landscape.natural",
    "elementType": "geometry.fill",
    "stylers": [{"color": "#f8fafc"}]
  },
  {
    "featureType": "poi",
    "elementType": "geometry",
    "stylers": [{"color": "#f1f5f9"}]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#475569"}]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry.fill",
    "stylers": [{"color": "#dcfce7"}]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#166534"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry.fill",
    "stylers": [{"color": "#ffffff"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#e2e8f0"}, {"weight": 1.0}]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry.fill",
    "stylers": [{"color": "#fef9c3"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#fef08a"}, {"weight": 0.8}]
  },
  {
    "featureType": "road.arterial",
    "elementType": "geometry.fill",
    "stylers": [{"color": "#ffffff"}]
  },
  {
    "featureType": "road.local",
    "elementType": "geometry.fill",
    "stylers": [{"color": "#ffffff"}]
  },
  {
    "featureType": "transit",
    "elementType": "all",
    "stylers": [{"visibility": "simplified"}]
  },
  {
    "featureType": "water",
    "elementType": "geometry.fill",
    "stylers": [{"color": "#bae6fd"}]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#0284c7"}]
  }
]''';

class ItineraryMapView extends StatefulWidget {
  final List<TripActivityModel> activities;
  final String destinationName;
  final double? centerLat;
  final double? centerLng;
  final Map<String, Map<String, double>> resolvedCoords;
  final double? height;
  final bool fullWidth;
  final Widget? topLeftWidget;
  final Widget? topRightWidget;
  final void Function(int index, TripActivityModel act)? onSpotSelected;

  const ItineraryMapView({
    super.key,
    required this.activities,
    required this.destinationName,
    this.centerLat,
    this.centerLng,
    this.resolvedCoords = const {},
    this.height,
    this.fullWidth = true,
    this.topLeftWidget,
    this.topRightWidget,
    this.onSpotSelected,
  });

  @override
  State<ItineraryMapView> createState() => _ItineraryMapViewState();
}

class _ItineraryMapViewState extends State<ItineraryMapView> {
  GoogleMapController? _mapController;
  int _selectedSpotIndex = 0;
  final ScrollController _scrollController = ScrollController();
  final Map<String, BitmapDescriptor> _markerIconCache = {};
  Set<Marker> _markers = {};
  List<LatLng> _roadRoutePoints = [];
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    _rebuildMarkers();
    _fetchRoadRoute();
  }

  @override
  void reassemble() {
    super.reassemble();
    _markerIconCache.clear();
    _rebuildMarkers();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ItineraryMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activities != widget.activities ||
        oldWidget.resolvedCoords != widget.resolvedCoords) {
      if (_selectedSpotIndex >= widget.activities.length) {
        _selectedSpotIndex = 0;
      }
      _rebuildMarkers();
      _fetchRoadRoute();
      final points = _computePoints();
      if (_mapController != null && points.isNotEmpty) {
        _fitMapToBounds(points);
      }
    }
  }

  Future<void> _fetchRoadRoute() async {
    final points = _computePoints();
    if (points.length < 2) {
      if (mounted) setState(() => _roadRoutePoints = points);
      return;
    }

    if (_roadRoutePoints.isEmpty) {
      _roadRoutePoints = points;
    }

    final roadPoints = await RouteDirectionService.fetchRoadRoute(points);
    if (mounted && roadPoints.isNotEmpty) {
      setState(() {
        _roadRoutePoints = roadPoints;
      });
    }
  }

  LatLng _getCityCenter() {
    if (widget.centerLat != null && widget.centerLng != null) {
      return LatLng(widget.centerLat!, widget.centerLng!);
    }
    final destLower = widget.destinationName.toLowerCase();
    for (final entry in _kCityCenters.entries) {
      if (destLower.contains(entry.key)) {
        return entry.value;
      }
    }
    // Default fallback (Shillong)
    return const LatLng(25.5788, 91.8933);
  }

  LatLng _getCoordinateForActivity(
      TripActivityModel act, int index, LatLng base) {
    if (widget.resolvedCoords.containsKey(act.id)) {
      final c = widget.resolvedCoords[act.id]!;
      return LatLng(c['lat']!, c['lng']!);
    }

    final actLower = act.name.toLowerCase();
    for (final entry in _kKnownPlaceCoords.entries) {
      if (actLower.contains(entry.key) || entry.key.contains(actLower)) {
        return entry.value;
      }
    }

    // Offset fallback sequence around destination
    final offsetAngle = (index * 60) * (math.pi / 180.0);
    final distance = 0.015 + (index * 0.007);
    return LatLng(
      base.latitude +
          (distance * (index % 2 == 0 ? 1 : -1) * (1.0 + (offsetAngle % 0.5))),
      base.longitude +
          (distance * (index % 3 == 0 ? 1 : -1) * (1.0 + (offsetAngle % 0.3))),
    );
  }

  List<LatLng> _computePoints() {
    final base = _getCityCenter();
    final List<LatLng> points = [];
    for (int i = 0; i < widget.activities.length; i++) {
      points.add(_getCoordinateForActivity(widget.activities[i], i, base));
    }
    return points;
  }

  Future<BitmapDescriptor> _getMarkerIcon({
    required int number,
    required bool isSelected,
    required bool isFirst,
  }) async {
    final cacheKey = "lavender_#DCC8FA_${number}_${isSelected}_$isFirst";
    if (_markerIconCache.containsKey(cacheKey)) {
      return _markerIconCache[cacheKey]!;
    }

    final icon = await _generateNumberedMarker(
      number: number,
      isSelected: isSelected,
      isFirst: isFirst,
    );
    _markerIconCache[cacheKey] = icon;
    return icon;
  }

  static Future<BitmapDescriptor> _generateNumberedMarker({
    required int number,
    required bool isSelected,
    required bool isFirst,
  }) async {
    // Elegant, standard pin sizing in logical points:
    // Regular: 26 pt, First: 30 pt, Selected: 34 pt
    final double logicalSize = isSelected ? 34.0 : (isFirst ? 30.0 : 26.0);
    const double pixelRatio = 3.0; // Render at 3x for crisp retina display
    final double canvasSize = logicalSize * pixelRatio;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, canvasSize, canvasSize));
    canvas.scale(pixelRatio, pixelRatio);

    final center = Offset(logicalSize / 2, logicalSize / 2);
    final radius = (logicalSize / 2) - 2.0;

    // Drop shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withAlpha(50)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
    canvas.drawCircle(center.translate(0, 1.2), radius, shadowPaint);

    // Radiant outer halo for first or selected destination
    if (isSelected || isFirst) {
      final haloPaint = Paint()
        ..color = isSelected
            ? const Color(0xFFDCC8FA).withAlpha(140) // Lavender halo
            : const Color(0xFF0F766E).withAlpha(65) // Subtle halo for #1
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(center, radius + 1.2, haloPaint);
    }

    // Outer crisp white ring
    final whiteBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, whiteBorderPaint);

    // Inner circular fill
    final Color fillColor = isSelected
        ? const Color(0xFFDCC8FA) // #DCC8FA Lavender for selected
        : (isFirst
            ? const Color(0xFF0F766E) // Deep Teal / Dark Green for #1
            : const Color(0xFF0D9488)); // Teal for other destinations

    final innerFillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - 1.8, innerFillPaint);

    // Number text
    final double fontSize = isSelected ? 15.0 : (isFirst ? 13.5 : 12.0);
    final textPainter = TextPainter(
      text: TextSpan(
        text: "$number",
        style: TextStyle(
          color: isSelected ? const Color(0xFF3B0764) : Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          fontFamily: 'Roboto',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - (textPainter.width / 2),
        center.dy - (textPainter.height / 2),
      ),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(canvasSize.toInt(), canvasSize.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    return BitmapDescriptor.bytes(
      bytes,
      width: logicalSize,
      height: logicalSize,
      imagePixelRatio: pixelRatio,
    );
  }

  Future<void> _rebuildMarkers() async {
    final points = _computePoints();
    final Set<Marker> markers = {};

    for (int i = 0; i < widget.activities.length; i++) {
      final act = widget.activities[i];
      final pt = points[i];
      final isSelected = i == _selectedSpotIndex;
      final isFirst = i == 0;

      final icon = await _getMarkerIcon(
        number: i + 1,
        isSelected: isSelected,
        isFirst: isFirst,
      );

      markers.add(
        Marker(
          markerId: MarkerId(
              "${act.id.isNotEmpty ? act.id : 'spot_$i'}_${isSelected ? 'sel_dcc8fa' : 'unsel'}"),
          position: pt,
          infoWindow: InfoWindow(
            title: "${i + 1}. ${act.name}",
            snippet:
                "${_formatTime(act.startDatetime)} – ${_formatTime(act.endDatetime)}",
          ),
          icon: icon,
          zIndexInt: isSelected ? 10 : (isFirst ? 5 : 1),
          onTap: () => _selectSpot(i, pt),
        ),
      );
    }

    if (mounted) {
      setState(() => _markers = markers);
    }
  }

  void _selectSpot(int index, [LatLng? target]) {
    setState(() => _selectedSpotIndex = index);
    _rebuildMarkers();

    if (_mapController != null && target != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(target, 15.0),
      );
    }
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        index * 175.w,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
    if (index >= 0 && index < widget.activities.length) {
      widget.onSpotSelected?.call(index, widget.activities[index]);
    }
  }

  void _fitMapToBounds(List<LatLng> points) {
    if (points.isEmpty || _mapController == null) return;

    if (points.length == 1) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(points.first, 14.5),
      );
      return;
    }

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    Future.delayed(const Duration(milliseconds: 150), () {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 65),
      );
    });
  }

  Future<void> _goToCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 5),
          ),
        );
        final userLatLng = LatLng(pos.latitude, pos.longitude);
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(userLatLng, 15.0),
        );
      } else {
        _fitMapToBounds(_computePoints());
      }
    } catch (_) {
      _fitMapToBounds(_computePoints());
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour;
    final minute = dt.minute;
    final period = hour >= 12 ? "PM" : "AM";
    final formattedHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final formattedMinute = minute.toString().padLeft(2, '0');
    return "$formattedHour:$formattedMinute $period";
  }

  @override
  Widget build(BuildContext context) {
    final baseCenter = _getCityCenter();
    final points = _computePoints();
    final stopCount = widget.activities.length;
    final mapHeight = widget.height ?? 430.h;

    final activeRoutePoints =
        _roadRoutePoints.isNotEmpty ? _roadRoutePoints : points;

    // Connecting road route between spots:
    // Outer white casing for supreme contrast + inner dark green / teal line
    final Set<Polyline> polylines = {
      if (activeRoutePoints.length >= 2) ...[
        Polyline(
          polylineId: PolylineId("route_casing_${activeRoutePoints.length}"),
          points: activeRoutePoints,
          color: Colors.white.withAlpha(220),
          width: 8,
          geodesic: true,
          jointType: JointType.round,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ),
        Polyline(
          polylineId: PolylineId("route_main_${activeRoutePoints.length}"),
          points: activeRoutePoints,
          color: const Color(0xFF0D9488), // Teal / Dark Green
          width: 5,
          geodesic: true,
          jointType: JointType.round,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ),
      ],
    };

    return Container(
      width: double.infinity,
      height: mapHeight,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: widget.fullWidth ? BorderRadius.zero : BorderRadius.circular(18.r),
        border: widget.fullWidth
            ? null
            : Border.all(
                color: const Color(0xFFE2E8F0),
                width: 1.0,
              ),
      ),
      child: ClipRRect(
        borderRadius: widget.fullWidth ? BorderRadius.zero : BorderRadius.circular(18.r),
        child: Stack(
          children: [
            // 1. Full-width Google Map with minimal light styling
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: points.isNotEmpty ? points.first : baseCenter,
                zoom: 13.5,
              ),
              style: _kMinimalLightMapStyle,
              onMapCreated: (ctrl) {
                _mapController = ctrl;
                if (points.isNotEmpty) {
                  _fitMapToBounds(points);
                }
              },
              markers: _markers,
              polylines: polylines,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
              scrollGesturesEnabled: true,
              zoomGesturesEnabled: true,
              rotateGesturesEnabled: true,
              tiltGesturesEnabled: true,
              gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                Factory<OneSequenceGestureRecognizer>(
                  () => EagerGestureRecognizer(),
                ),
              },
            ),

            // 2. Top-Left Floating Badge: "3 stops"
            if (widget.topLeftWidget != null)
              Positioned(
                top: 14.h,
                left: 14.w,
                child: widget.topLeftWidget!,
              )
            else
              Positioned(
                top: 14.h,
                left: 14.w,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22.r),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withAlpha(30),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.all(4.5.w),
                        decoration: const BoxDecoration(
                          color: Color(0xFF0D9488),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.location_on_rounded,
                          size: 12.sp,
                          color: Colors.white,
                        ),
                      ),
                      8.w.horizontalSpace,
                      Text(
                        "$stopCount ${stopCount == 1 ? 'stop' : 'stops'}",
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // 3. Top-Right Map Controls: Reset view / Re-center + My Location
            if (widget.topRightWidget != null)
              Positioned(
                top: 14.h,
                right: 14.w,
                child: widget.topRightWidget!,
              )
            else
              Positioned(
                top: 14.h,
                right: 14.w,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Reset / Fit all bounds button
                    GestureDetector(
                      onTap: () {
                        if (points.isNotEmpty) {
                          _fitMapToBounds(points);
                        } else {
                          _mapController?.animateCamera(
                            CameraUpdate.newLatLngZoom(baseCenter, 13.0),
                          );
                        }
                      },
                      child: Container(
                        width: 38.w,
                        height: 38.w,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.r),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0F172A).withAlpha(30),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.crop_free_rounded,
                            color: const Color(0xFF0D9488),
                            size: 20.sp,
                          ),
                        ),
                      ),
                    ),
                    8.h.verticalSpace,
                    // Return to current location button
                    GestureDetector(
                      onTap: _isLocating ? null : _goToCurrentLocation,
                      child: Container(
                        width: 38.w,
                        height: 38.w,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.r),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0F172A).withAlpha(30),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: _isLocating
                              ? SizedBox(
                                  width: 16.w,
                                  height: 16.w,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF0D9488),
                                  ),
                                )
                              : Icon(
                                  Icons.my_location_rounded,
                                  color: const Color(0xFF0D9488),
                                  size: 19.sp,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // 4. Bottom Horizontal Carousel of spots
            if (widget.activities.isNotEmpty)
              Positioned(
                bottom: 12.h,
                left: 12.w,
                right: 12.w,
                child: SizedBox(
                  height: 72.h,
                  child: ListView.separated(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.activities.length,
                    separatorBuilder: (_, __) => 8.w.horizontalSpace,
                    itemBuilder: (context, index) {
                      final act = widget.activities[index];
                      final isSelected = index == _selectedSpotIndex;
                      final isFirst = index == 0;
                      final timeRange =
                          "${_formatTime(act.startDatetime)} – ${_formatTime(act.endDatetime)}";
                      final pt = points[index];

                      return GestureDetector(
                        onTap: () => _selectSpot(index, pt),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: EdgeInsets.symmetric(
                            horizontal: 14.w,
                            vertical: 8.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFDCC8FA)
                                  : (isFirst
                                      ? const Color(0xFF0D9488)
                                      : const Color(0xFFE2E8F0)),
                              width: isSelected ? 2.0 : (isFirst ? 1.5 : 1.0),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isSelected
                                    ? const Color(0xFFDCC8FA).withAlpha(100)
                                    : const Color(0xFF0F172A).withAlpha(20),
                                blurRadius: isSelected ? 10 : 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 11.r,
                                    backgroundColor: isSelected
                                        ? const Color(0xFFDCC8FA)
                                        : (isFirst
                                            ? const Color(0xFF0F766E)
                                            : const Color(0xFF0D9488)),
                                    child: Text(
                                      "${index + 1}",
                                      style: TextStyle(
                                        fontSize: 10.5.sp,
                                        fontWeight: FontWeight.w900,
                                        color: isSelected
                                            ? const Color(0xFF3B0764)
                                            : Colors.white,
                                      ),
                                    ),
                                  ),
                                  8.w.horizontalSpace,
                                  ConstrainedBox(
                                    constraints:
                                        BoxConstraints(maxWidth: 145.w),
                                    child: Text(
                                      act.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13.sp,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              3.h.verticalSpace,
                              Padding(
                                padding: EdgeInsets.only(left: 30.w),
                                child: Text(
                                  timeRange,
                                  style: TextStyle(
                                    fontSize: 10.5.sp,
                                    color: const Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              )
            else
              // Empty banner when no spots added yet
              Positioned(
                bottom: 14.h,
                left: 16.w,
                right: 16.w,
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withAlpha(20),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: const Color(0xFF0D9488),
                        size: 18.sp,
                      ),
                      8.w.horizontalSpace,
                      Expanded(
                        child: Text(
                          "No spots planned for this day yet. Tap '+ Add a spot' to add places!",
                          style: TextStyle(
                            fontSize: 11.5.sp,
                            color: const Color(0xFF475569),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
