import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wonder_souls/src/config/core/injector/injector.dart';
import 'package:wonder_souls/src/config/core/model/place_model.dart';
import 'package:wonder_souls/src/config/core/services/api_services.dart';
import 'package:wonder_souls/src/config/model/failure.dart';
import 'package:wonder_souls/src/config/model/success.dart';
import 'package:wonder_souls/src/config/utils/api_constant.dart';
import 'trip_wizard_state.dart';

class TripWizardCubit extends Cubit<TripWizardState> {
  TripWizardCubit() : super(const TripWizardState());

  void init(PlaceModel destination) {
    emit(state.copyWith(
      destination: destination,
      currentStep: 0,
      name: "Trip to ${destination.name}",
    ));
  }

  void setName(String name) {
    emit(state.copyWith(name: name));
  }

  void setDescription(String description) {
    emit(state.copyWith(description: description));
  }

  void setIsPublic(bool isPublic) {
    emit(state.copyWith(isPublic: isPublic));
  }

  void setPartyType(String type) {
    emit(state.copyWith(partyType: type));
  }

  void setDates(DateTime? start, DateTime? end) {
    emit(state.copyWith(startDate: start, endDate: end));
  }

  void toggleInterest(String interest) {
    final currentInterests = List<String>.from(state.interests);
    if (currentInterests.contains(interest)) {
      currentInterests.remove(interest);
    } else {
      currentInterests.add(interest);
    }
    emit(state.copyWith(interests: currentInterests));
  }

  void setBudgetLevel(String level) {
    emit(state.copyWith(budgetLevel: level));
  }

  void setBudgetDetails({
    required String currency,
    required double totalEstimated,
    required double transportation,
    required double accommodation,
    required double food,
    required double activities,
  }) {
    emit(state.copyWith(
      currency: currency,
      totalEstimated: totalEstimated,
      transportationBudget: transportation,
      accommodationBudget: accommodation,
      foodBudget: food,
      activitiesBudget: activities,
    ));
  }

  void addCollaborator(String email) {
    final current = List<Map<String, dynamic>>.from(state.collaborators);
    current.add({
      "userEmail": email,
      "permissionLevel": "editor",
    });
    emit(state.copyWith(collaborators: current));
  }

  void removeCollaborator(String email) {
    final current = List<Map<String, dynamic>>.from(state.collaborators);
    current.removeWhere((c) => c["userEmail"] == email);
    emit(state.copyWith(collaborators: current));
  }

  void nextStep() {
    if (state.currentStep < 8) {
      emit(state.copyWith(currentStep: state.currentStep + 1));
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      emit(state.copyWith(currentStep: state.currentStep - 1));
    }
  }

  void goToStep(int step) {
    if (step >= 0 && step <= 8) {
      emit(state.copyWith(currentStep: step));
    }
  }

  /// Call the AI FastAPI service to generate a day-by-day itinerary
  Future<void> generateItinerary() async {
    emit(state.copyWith(
      status: TripWizardStatus.generatingItinerary,
      currentStep: 7, // Move to GeneratingStep
    ));

    final payload = {
      "destination": state.destination?.name ?? "",
      "startDate": state.startDate?.toUtc().toIso8601String() ??
          DateTime.now().toUtc().toIso8601String(),
      "endDate": state.endDate?.toUtc().toIso8601String() ??
          DateTime.now()
              .add(const Duration(days: 3))
              .toUtc()
              .toIso8601String(),
      "whoIsGoing": state.partyType ?? "solo",
      "travelTastes": state.interests,
      "budget": {
        "budgetType": state.budgetLevel ?? "flexible",
        "totalEstimated": state.totalEstimated,
        "currency": state.currency.isEmpty ? "USD" : state.currency,
        "byCategory": {
          "transportation": state.transportationBudget,
          "accommodation": state.accommodationBudget,
          "food": state.foodBudget,
          "activities": state.activitiesBudget,
        }
      },
      "tripName":
          state.name ?? "Trip to ${state.destination?.name ?? 'Destination'}",
      "description": state.description ?? "",
    };

    try {
      final dio = Dio(BaseOptions(
        baseUrl: ApiConstants.aiBaseUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
      ));

      final response = await dio.post(
        ApiConstants.generateItinerary,
        data: payload,
      );

      if (response.statusCode == 200 && response.data != null) {
        final itineraryData = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : <String, dynamic>{};

        emit(state.copyWith(
          status: TripWizardStatus.itineraryReady,
          generatedItinerary: itineraryData,
          currentStep: 8, // Move to ItineraryResultStep
        ));
      } else {
        emit(state.copyWith(
          status: TripWizardStatus.failure,
          errorMessage: "Failed to generate itinerary. Please try again.",
          currentStep: 6,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: TripWizardStatus.failure,
        errorMessage: "AI service error: ${e.toString()}",
        currentStep: 6,
      ));
    }
  }

  /// Save the trip to the .NET backend after the itinerary is approved
  Future<void> saveTrip() async {
    emit(state.copyWith(status: TripWizardStatus.loading));

    final payload = {
      "name":
          state.name ?? "Trip to ${state.destination?.name ?? 'Destination'}",
      "description": state.description ?? "",
      "startDate": state.startDate?.toUtc().toIso8601String() ??
          DateTime.now().toUtc().toIso8601String(),
      "endDate": state.endDate?.toUtc().toIso8601String() ??
          DateTime.now()
              .add(const Duration(days: 3))
              .toUtc()
              .toIso8601String(),
      "mainDestination": state.destination?.name ?? "",
      "isPublic": state.isPublic,
      "whoIsGoing": state.partyType ?? "solo",
      "travelTastes": state.interests,
      "budget": {
        "budgetType": state.budgetLevel ?? "flexible",
        "totalEstimated": state.totalEstimated,
        "currency": state.currency.isEmpty ? "USD" : state.currency,
        "byCategory": {
          "transportation": state.transportationBudget,
          "accommodation": state.accommodationBudget,
          "food": state.foodBudget,
          "activities": state.activitiesBudget,
        }
      }
    };

    try {
      final apiService = sl<ApiService>();
      final result = await apiService.post<void>(
        ApiConstants.createTrip,
        data: payload,
        fromJson: (_) {},
      );

      if (result is Success<void>) {
        emit(state.copyWith(status: TripWizardStatus.success));
      } else if (result is Failure<void>) {
        emit(state.copyWith(
          status: TripWizardStatus.failure,
          errorMessage: result.message,
          currentStep: 6,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: TripWizardStatus.failure,
        errorMessage: e.toString(),
        currentStep: 6,
      ));
    }
  }

  /// Legacy method – now calls generateItinerary instead
  Future<void> generateTrip() => generateItinerary();
}
