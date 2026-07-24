import 'package:wonder_souls/src/features/auth/data/model/budget.dart';
import 'package:wonder_souls/src/features/auth/data/model/destination_model.dart';
import 'package:wonder_souls/src/features/auth/domain/enitiy/trip.dart';

class TripModel extends Trip {
  const TripModel({
    required super.id,
    required super.ownerId,
    required super.ownerName,
    required super.name,
    super.description,
    required super.startDate,
    required super.endDate,
    super.coverImage,
    required super.mainDestination,
    required super.isPublic,
    required super.collaborators,
    super.destinations,
    super.days,
    required super.budget,
    required super.createdAt,
    required super.updatedAt,
  });

  factory TripModel.fromJson(Map<String, dynamic> json) {
    return TripModel(
      id: json['id'] ?? '',
      ownerId: json['ownerId'] ?? '',
      ownerName: json['ownerName'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      coverImage: json['coverImage'],
      mainDestination: json['mainDestination'] ?? '',
      isPublic: json['isPublic'] ?? false,
      collaborators: List<String>.from(json['collaborators'] ?? []),
      destinations: json['destinations'] != null
          ? (json['destinations'] as List)
                .map((e) => DestinationModel.fromJson(e))
                .toList()
          : null,
      budget: BudgetModel.fromJson(json['budget']),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}
