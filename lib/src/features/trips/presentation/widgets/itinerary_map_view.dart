import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
  'bali': LatLng(-8.4095, 115.1889),
};

class ItineraryMapView extends StatefulWidget {
  final List<TripActivityModel> activities;
  final String destinationName;
  final double? centerLat;
  final double? centerLng;
  final Map<String, Map<String, double>> resolvedCoords;

  const ItineraryMapView({
    super.key,
    required this.activities,
    required this.destinationName,
    this.centerLat,
    this.centerLng,
    this.resolvedCoords = const {},
  });

  @override
  State<ItineraryMapView> createState() => _ItineraryMapViewState();
}

class _ItineraryMapViewState extends State<ItineraryMapView> {
  GoogleMapController? _mapController;
  int _selectedSpotIndex = 0;
  final ScrollController _scrollController = ScrollController();

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
      final points = _computePoints();
      if (_mapController != null && points.isNotEmpty) {
        _fitMapToBounds(points);
      }
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
    final offsetAngle = (index * 60) * (3.14159 / 180.0);
    final distance = 0.015 + (index * 0.006);
    return LatLng(
      base.latitude + (distance * (index % 2 == 0 ? 1 : -1) * (1.0 + (offsetAngle % 0.5))),
      base.longitude + (distance * (index % 3 == 0 ? 1 : -1) * (1.0 + (offsetAngle % 0.3))),
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

  void _selectSpot(int index, [LatLng? target]) {
    setState(() => _selectedSpotIndex = index);
    if (_mapController != null && target != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(target, 15.0),
      );
    }
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        index * 170.w,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
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

    Future.delayed(const Duration(milliseconds: 250), () {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 50),
      );
    });
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

    // Set of markers pointing out spots added by user
    final Set<Marker> markers = {};
    for (int i = 0; i < widget.activities.length; i++) {
      final act = widget.activities[i];
      final pt = points[i];
      final isSelected = i == _selectedSpotIndex;

      markers.add(
        Marker(
          markerId: MarkerId(act.id.isNotEmpty ? act.id : "spot_$i"),
          position: pt,
          infoWindow: InfoWindow(
            title: "${i + 1}. ${act.name}",
            snippet:
                "${_formatTime(act.startDatetime)} – ${_formatTime(act.endDatetime)}",
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            isSelected ? BitmapDescriptor.hueRose : BitmapDescriptor.hueCyan,
          ),
          onTap: () => _selectSpot(i, pt),
        ),
      );
    }

    // Connecting route line between spots
    final Set<Polyline> polylines = {
      if (points.length >= 2)
        Polyline(
          polylineId: PolylineId("itinerary_route_${points.length}"),
          points: points,
          color: const Color(0xFF0D9488),
          width: 5,
          geodesic: true,
          jointType: JointType.round,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ),
    };

    return Container(
      height: 385.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withAlpha(12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18.r),
        child: Stack(
          children: [
            // 1. Live Google Map centered on destination with spots and connecting lines
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: points.isNotEmpty ? points.first : baseCenter,
                zoom: 13.0,
              ),
              onMapCreated: (ctrl) {
                _mapController = ctrl;
                if (points.isNotEmpty) {
                  _fitMapToBounds(points);
                }
              },
              markers: markers,
              polylines: polylines,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
            ),

            // 2. Top-Left Floating Badge: "X stops"
            Positioned(
              top: 14.h,
              left: 14.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withAlpha(25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: const BoxDecoration(
                        color: Color(0xFF0D9488),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.location_on,
                        size: 11.5.sp,
                        color: Colors.white,
                      ),
                    ),
                    7.w.horizontalSpace,
                    Text(
                      "$stopCount ${stopCount == 1 ? 'stop' : 'stops'}",
                      style: TextStyle(
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 3. Top-Right Floating Re-center Button
            Positioned(
              top: 14.h,
              right: 14.w,
              child: GestureDetector(
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
                  width: 36.w,
                  height: 36.w,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withAlpha(25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.crop_free_rounded,
                      color: const Color(0xFF0D9488),
                      size: 19.sp,
                    ),
                  ),
                ),
              ),
            ),

            // 4. Bottom Horizontal Carousel of spots pointing out user added places
            if (widget.activities.isNotEmpty)
              Positioned(
                bottom: 12.h,
                left: 12.w,
                right: 12.w,
                child: SizedBox(
                  height: 66.h,
                  child: ListView.separated(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.activities.length,
                    separatorBuilder: (_, __) => 8.w.horizontalSpace,
                    itemBuilder: (context, index) {
                      final act = widget.activities[index];
                      final isSelected = index == _selectedSpotIndex;
                      final timeRange =
                          "${_formatTime(act.startDatetime)} – ${_formatTime(act.endDatetime)}";
                      final pt = points[index];

                      return GestureDetector(
                        onTap: () => _selectSpot(index, pt),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 8.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14.r),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF0D9488)
                                  : const Color(0xFFE2E8F0),
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0F172A).withAlpha(25),
                                blurRadius: 8,
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
                                    radius: 9.r,
                                    backgroundColor: isSelected
                                        ? const Color(0xFF0D9488)
                                        : const Color(0xFF0F172A),
                                    child: Text(
                                      "${index + 1}",
                                      style: TextStyle(
                                        fontSize: 9.5.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  7.w.horizontalSpace,
                                  ConstrainedBox(
                                    constraints:
                                        BoxConstraints(maxWidth: 130.w),
                                    child: Text(
                                      act.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12.sp,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              3.h.verticalSpace,
                              Padding(
                                padding: EdgeInsets.only(left: 25.w),
                                child: Text(
                                  timeRange,
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    color: const Color(0xFF64748B),
                                    fontWeight: FontWeight.w400,
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
                          "No spots planned yet. Tap '+ Add a spot' above to add places!",
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
