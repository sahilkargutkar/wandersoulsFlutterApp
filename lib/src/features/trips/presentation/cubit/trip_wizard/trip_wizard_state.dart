import 'package:equatable/equatable.dart';
import 'package:wonder_souls/src/config/core/model/place_model.dart';

enum TripWizardStatus { initial, loading, generatingItinerary, itineraryReady, success, failure }

class TripWizardState extends Equatable {
  final PlaceModel? destination;
  final String? partyType;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String> interests;
  final String? budgetLevel;
  final List<Map<String, dynamic>> collaborators;
  final int currentStep;

  // New API fields
  final String? name;
  final String? description;
  final bool isPublic;
  final String currency;
  final double totalEstimated;
  final double transportationBudget;
  final double accommodationBudget;
  final double foodBudget;
  final double activitiesBudget;
  
  // Status fields
  final TripWizardStatus status;
  final String? errorMessage;

  // AI-generated itinerary
  final Map<String, dynamic>? generatedItinerary;

  const TripWizardState({
    this.destination,
    this.partyType,
    this.startDate,
    this.endDate,
    this.interests = const [],
    this.budgetLevel,
    this.collaborators = const [],
    this.currentStep = 0,
    this.name,
    this.description,
    this.isPublic = true,
    this.currency = "USD",
    this.totalEstimated = 0.0,
    this.transportationBudget = 0.0,
    this.accommodationBudget = 0.0,
    this.foodBudget = 0.0,
    this.activitiesBudget = 0.0,
    this.status = TripWizardStatus.initial,
    this.errorMessage,
    this.generatedItinerary,
  });

  TripWizardState copyWith({
    PlaceModel? destination,
    String? partyType,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? interests,
    String? budgetLevel,
    List<Map<String, dynamic>>? collaborators,
    int? currentStep,
    String? name,
    String? description,
    bool? isPublic,
    String? currency,
    double? totalEstimated,
    double? transportationBudget,
    double? accommodationBudget,
    double? foodBudget,
    double? activitiesBudget,
    TripWizardStatus? status,
    String? errorMessage,
    Map<String, dynamic>? generatedItinerary,
  }) {
    return TripWizardState(
      destination: destination ?? this.destination,
      partyType: partyType ?? this.partyType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      interests: interests ?? this.interests,
      budgetLevel: budgetLevel ?? this.budgetLevel,
      collaborators: collaborators ?? this.collaborators,
      currentStep: currentStep ?? this.currentStep,
      name: name ?? this.name,
      description: description ?? this.description,
      isPublic: isPublic ?? this.isPublic,
      currency: currency ?? this.currency,
      totalEstimated: totalEstimated ?? this.totalEstimated,
      transportationBudget: transportationBudget ?? this.transportationBudget,
      accommodationBudget: accommodationBudget ?? this.accommodationBudget,
      foodBudget: foodBudget ?? this.foodBudget,
      activitiesBudget: activitiesBudget ?? this.activitiesBudget,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      generatedItinerary: generatedItinerary ?? this.generatedItinerary,
    );
  }

  @override
  List<Object?> get props => [
        destination,
        partyType,
        startDate,
        endDate,
        interests,
        budgetLevel,
        collaborators,
        currentStep,
        name,
        description,
        isPublic,
        currency,
        totalEstimated,
        transportationBudget,
        accommodationBudget,
        foodBudget,
        activitiesBudget,
        status,
        errorMessage,
        generatedItinerary,
      ];
}
