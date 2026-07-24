import 'package:wonder_souls/src/config/core/model/geo_point.dart';
import 'package:wonder_souls/src/features/auth/domain/enitiy/destination.dart';

class DestinationModel extends Destination {
  const DestinationModel({
    required super.destinationId,
    required super.name,
    required super.country,
    super.region,
    required super.coordinates,
    required super.arrivalDate,
    required super.departureDate,
    required super.orderIndex,
    required super.status,
  });

  factory DestinationModel.fromJson(Map<String, dynamic> json) {
    return DestinationModel(
      destinationId: json['destinationId'] ?? '',
      name: json['name'] ?? '',
      country: json['country'] ?? '',
      region: json['region'],
      coordinates: GeoPoint.fromJson(json['coordinates']),
      arrivalDate: DateTime.parse(json['arrivalDate']),
      departureDate: DateTime.parse(json['departureDate']),
      orderIndex: json['orderIndex'] ?? 0,
      status: json['status'] ?? '',
    );
  }
}
