import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MarkerData {
  final String id;
  final String title;
  final double lat;
  final double lng;

  MarkerData({
    required this.id,
    required this.title,
    required this.lat,
    required this.lng,
  });
}

class MapView extends StatefulWidget {
  final List<MarkerData> markers;

  const MapView({super.key, required this.markers});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  GoogleMapController? mapController;

  @override
  void didUpdateWidget(covariant MapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _fitBounds();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _fitBounds();
  }

  void _fitBounds() {
    if (mapController == null || widget.markers.isEmpty) return;

    if (widget.markers.length == 1) {
      mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(widget.markers.first.lat, widget.markers.first.lng),
          14.0,
        ),
      );
      return;
    }

    double minLat = widget.markers.first.lat;
    double maxLat = widget.markers.first.lat;
    double minLng = widget.markers.first.lng;
    double maxLng = widget.markers.first.lng;

    for (var m in widget.markers) {
      if (m.lat < minLat) minLat = m.lat;
      if (m.lat > maxLat) maxLat = m.lat;
      if (m.lng < minLng) minLng = m.lng;
      if (m.lng > maxLng) maxLng = m.lng;
    }

    mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        50.0, // padding
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Set<Marker> googleMarkers = widget.markers.map((m) {
      return Marker(
        markerId: MarkerId(m.id),
        position: LatLng(m.lat, m.lng),
        infoWindow: InfoWindow(title: m.title),
      );
    }).toSet();

    final LatLng initialCenter = widget.markers.isNotEmpty
        ? LatLng(widget.markers.first.lat, widget.markers.first.lng)
        : const LatLng(20.5937, 78.9629); // default center

    return GoogleMap(
      onMapCreated: _onMapCreated,
      markers: googleMarkers,
      initialCameraPosition: CameraPosition(
        target: initialCenter,
        zoom: widget.markers.isNotEmpty ? 12.0 : 4.0,
      ),
      myLocationButtonEnabled: false,
      zoomControlsEnabled: true,
    );
  }
}
