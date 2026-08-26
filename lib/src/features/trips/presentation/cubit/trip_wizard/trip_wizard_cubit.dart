import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wonder_souls/src/config/core/injector/injector.dart';
import 'package:wonder_souls/src/config/core/model/place_model.dart';
import 'package:wonder_souls/src/config/core/services/api_services.dart';
import 'package:wonder_souls/src/config/model/failure.dart';
import 'package:wonder_souls/src/config/model/success.dart';
import 'package:wonder_souls/src/config/core/services/google_map_services.dart';
import 'package:wonder_souls/src/config/core/services/google_places_new_service.dart';
import 'package:flutter/foundation.dart';
import 'package:wonder_souls/src/config/utils/api_constant.dart';
import 'package:wonder_souls/src/features/auth/data/datasource/auth_local_data_source.dart';
import 'trip_wizard_state.dart';

class TripWizardCubit extends Cubit<TripWizardState> {
  TripWizardCubit() : super(const TripWizardState());

  void init(PlaceModel destination) {
    emit(
      state.copyWith(
        destination: destination,
        currentStep: 0,
        name: "Trip to ${destination.name}",
      ),
    );
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
    emit(
      state.copyWith(
        currency: currency,
        totalEstimated: totalEstimated,
        transportationBudget: transportation,
        accommodationBudget: accommodation,
        foodBudget: food,
        activitiesBudget: activities,
      ),
    );
  }

  void addCollaborator(String email) {
    final current = List<Map<String, dynamic>>.from(state.collaborators);
    current.add({"userEmail": email, "permissionLevel": "editor"});
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

  /// Call the .NET backend service to create the trip and generate a day-by-day itinerary
  Future<void> generateItinerary() async {
    emit(
      state.copyWith(
        status: TripWizardStatus.generatingItinerary,
        currentStep: 7, // Move to GeneratingStep
      ),
    );

    String imageUrl = "";
    final destinationName =
        state.destination?.name ?? state.destination?.description ?? "";
    String? placeId = state.destination?.placeId;

    try {
      final placesService = sl.isRegistered<GooglePlacesNewService>()
          ? sl<GooglePlacesNewService>()
          : GooglePlacesNewService();

      if (placeId == null || placeId.isEmpty) {
        if (destinationName.isNotEmpty) {
          placeId = await placesService.searchPlaceId(destinationName);
        }
      }

      if (placeId != null && placeId.isNotEmpty) {
        final details = await placesService.getPlaceDetails(placeId);
        final photos = details?["photos"] as List?;
        if (photos != null && photos.isNotEmpty) {
          final photoName = photos.first["name"];
          if (photoName != null) {
            final uri = await placesService.getPhotoUri(photoName);
            if (uri != null && uri.isNotEmpty) {
              imageUrl = uri;
            }
          }
        }
      }

      // Legacy Google Maps Api fallback
      if (imageUrl.isEmpty && placeId != null && placeId.isNotEmpty) {
        final googleMapsApiService = sl<GoogleMapsApiService>();
        final detailsRes = await googleMapsApiService.getRequest(
          "maps/api/place/details/json",
          {
            "place_id": placeId,
            "fields": "photos",
            "key": googleMapsApiService.apiKey,
          },
        );
        if (detailsRes["status"] == "OK" && detailsRes["result"] != null) {
          final photos = detailsRes["result"]["photos"] as List?;
          if (photos != null && photos.isNotEmpty) {
            final photoRef = photos.first["photo_reference"];
            if (photoRef != null) {
              imageUrl =
                  "https://maps.googleapis.com/maps/api/place/photo?maxwidth=1200&photo_reference=$photoRef&key=${googleMapsApiService.apiKey}";
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Failed to fetch Google Place image: $e");
    }

    final user = sl<AuthLocalDataSource>().getUser();
    final ownerId = user?.id ?? "";
    final ownerName = user?.name ?? user?.userName ?? "";

    if (ownerId.isEmpty) {
      emit(
        state.copyWith(
          status: TripWizardStatus.failure,
          errorMessage: "User session not found. Please log in again.",
          currentStep: 6,
        ),
      );
      return;
    }

    final payload = {
      "ownerId": ownerId,
      "OwnerId": ownerId,
      "ownerName": ownerName,
      "OwnerName": ownerName,
      "name":
          state.name ?? "Trip to ${state.destination?.name ?? 'Destination'}",
      "description": state.description ?? "",
      "startDate":
          state.startDate?.toUtc().toIso8601String() ??
          DateTime.now().toUtc().toIso8601String(),
      "endDate":
          state.endDate?.toUtc().toIso8601String() ??
          DateTime.now().add(const Duration(days: 3)).toUtc().toIso8601String(),
      "mainDestination": state.destination?.name ?? "",
      "isPublic": state.isPublic,
      "whoIsGoing": state.partyType ?? "solo",
      "travelTastes": state.interests,
      "imageUrl": imageUrl,
      "image": imageUrl,
      "coverImage": imageUrl,
      "thumbnailUrl": imageUrl,
      "photoUrl": imageUrl,
      "photo": imageUrl,
      "collaborators": state.collaborators
          .map((c) => c["email"] ?? c["name"] ?? "")
          .toList(),
      "budget": {
        "budgetType": state.budgetLevel ?? "flexible",
        "totalEstimated": state.totalEstimated,
        "currency": state.currency.isEmpty ? "USD" : state.currency,
        "byCategory": {
          "transportation": state.transportationBudget,
          "accommodation": state.accommodationBudget,
          "food": state.foodBudget,
          "activities": state.activitiesBudget,
        },
      },
    };

    try {
      final apiService = sl<ApiService>();
      final result = await apiService.post<dynamic>(
        ApiConstants.createTrip,
        data: payload,
        fromJson: (data) => data,
      );

      if (result is Success<dynamic>) {
        Map<String, dynamic> itineraryData = {};
        if (result.data is Map<String, dynamic>) {
          final rawMap = result.data as Map<String, dynamic>;
          // Handle enveloped response {"data": {"itinerary": ...}} or direct {"itinerary": ...}
          if (rawMap.containsKey("data") &&
              rawMap["data"] is Map<String, dynamic>) {
            final innerData = rawMap["data"] as Map<String, dynamic>;
            if (innerData.containsKey("itinerary")) {
              itineraryData = innerData;
            } else {
              itineraryData = rawMap;
            }
          } else {
            itineraryData = rawMap;
          }
        }

        emit(
          state.copyWith(
            status: TripWizardStatus.itineraryReady,
            generatedItinerary: itineraryData,
            currentStep: 8, // Move to ItineraryResultStep
          ),
        );
      } else if (result is Failure<dynamic>) {
        emit(
          state.copyWith(
            status: TripWizardStatus.failure,
            errorMessage: result.message,
            currentStep: 6,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: TripWizardStatus.failure,
          errorMessage: "Failed to generate itinerary: ${e.toString()}",
          currentStep: 6,
        ),
      );
    }
  }

  /// Complete the trip creation wizard (trip is already saved to the backend during generation)
  Future<void> saveTrip() async {
    emit(state.copyWith(status: TripWizardStatus.loading));
    // Since the trip was already created via `/api/Trips/create-trip` in generateItinerary,
    // we can transition directly to success.
    await Future.delayed(const Duration(milliseconds: 500));
    emit(state.copyWith(status: TripWizardStatus.success));
  }

  /// Legacy method – now calls generateItinerary instead
  Future<void> generateTrip() => generateItinerary();
}
