import 'package:equatable/equatable.dart';
import 'package:wonder_souls/src/config/core/model/geo_point.dart';

class Destination extends Equatable {
  final String destinationId;
  final String name;
  final String country;
  final String? region;
  final GeoPoint coordinates;
  final DateTime arrivalDate;
  final DateTime departureDate;
  final int orderIndex;
  final String status;

  const Destination({
    required this.destinationId,
    required this.name,
    required this.country,
    this.region,
    required this.coordinates,
    required this.arrivalDate,
    required this.departureDate,
    required this.orderIndex,
    required this.status,
  });

  @override
  List<Object?> get props => [
    destinationId,
    name,
    country,
    region,
    coordinates,
    arrivalDate,
    departureDate,
    orderIndex,
    status,
  ];
}
