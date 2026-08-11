import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wonder_souls/src/config/core/model/place_model.dart';

class SavedPlacesCubit extends Cubit<List<PlaceModel>> {
  final SharedPreferences _prefs;
  static const String _savedPlacesKey = 'saved_places_key';

  SavedPlacesCubit(this._prefs) : super([]) {
    _loadSavedPlaces();
  }

  void _loadSavedPlaces() {
    try {
      final savedString = _prefs.getString(_savedPlacesKey);
      if (savedString != null) {
        final List<dynamic> decodedList = json.decode(savedString);
        final List<PlaceModel> places = decodedList
            .map((item) => PlaceModel.fromJson(item as Map<String, dynamic>))
            .toList();
        emit(places);
      }
    } catch (e) {
      // If decoding fails, emit empty list
      emit([]);
    }
  }

  void toggleSave(PlaceModel place) {
    final currentList = List<PlaceModel>.from(state);

    // Check if place is already saved using placeId (or name as fallback)
    final isSavedIndex = currentList.indexWhere((p) {
      if (p.placeId.isNotEmpty && place.placeId.isNotEmpty) {
        return p.placeId == place.placeId;
      }
      return p.name == place.name;
    });

    if (isSavedIndex >= 0) {
      // Remove it
      currentList.removeAt(isSavedIndex);
    } else {
      // Add it
      currentList.add(place);
    }

    emit(currentList);
    _saveToPrefs(currentList);
  }

  void _saveToPrefs(List<PlaceModel> places) {
    final encodedList = places.map((p) => p.toJson()).toList();
    _prefs.setString(_savedPlacesKey, json.encode(encodedList));
  }
}
