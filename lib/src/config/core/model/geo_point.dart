class GeoPoint {
  final String type;
  final List<double> coordinates;

  const GeoPoint({required this.type, required this.coordinates});

  factory GeoPoint.fromJson(Map<String, dynamic> json) {
    return GeoPoint(
      type: json['type'],
      coordinates: List<double>.from(json['coordinates']),
    );
  }

  Map<String, dynamic> toJson() => {'type': type, 'coordinates': coordinates};
}
