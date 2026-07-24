import 'package:equatable/equatable.dart';
import 'package:wonder_souls/src/features/auth/domain/enitiy/budget.dart';
import 'package:wonder_souls/src/features/auth/domain/enitiy/destination.dart';
import 'package:wonder_souls/src/features/auth/domain/enitiy/trip_day.dart';

class Trip extends Equatable {
  final String id;
  final String ownerId;
  final String ownerName;
  final String name;
  final String? description;
  final DateTime startDate;
  final DateTime endDate;
  final String? coverImage;
  final String mainDestination;
  final bool isPublic;
  final List<String> collaborators;
  final List<Destination>? destinations;
  final List<TripDay>? days;
  final Budget budget;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Trip({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.name,
    this.description,
    required this.startDate,
    required this.endDate,
    this.coverImage,
    required this.mainDestination,
    required this.isPublic,
    required this.collaborators,
    this.destinations,
    this.days,
    required this.budget,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    ownerId,
    ownerName,
    name,
    description,
    startDate,
    endDate,
    coverImage,
    mainDestination,
    isPublic,
    collaborators,
    destinations,
    days,
    budget,
    createdAt,
    updatedAt,
  ];
}
