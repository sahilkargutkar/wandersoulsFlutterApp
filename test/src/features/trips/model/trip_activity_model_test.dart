import 'package:flutter_test/flutter_test.dart';
import 'package:wonder_souls/src/features/trips/model/trip_activity_model.dart';

void main() {
  group('TripActivityModel Tests', () {
    test('fromJson - parses category successfully when it is an integer', () {
      final json = {
        "id": "88823510-0b57-470b-92ef-34d9264945a0",
        "tripId": "6a7ec47a19591b12bcbf874c",
        "placeId": "61667572695f686172617261a75",
        "name": "Afuri Harajuku",
        "bookingReference": "",
        "startDatetime": "2026-08-18T09:00:00Z",
        "endDatetime": "2026-08-18T10:00:00Z",
        "currency": "USD",
        "bookingUrl": "",
        "confirmationDocumentUrl": "",
        "activityDetails": {
          "category": 1,
          "participants": [],
          "meetingPoint": "",
          "duration": 60,
          "difficulty": "Easy",
          "ageRestriction": "None",
          "cost": 0
        }
      };

      final model = TripActivityModel.fromJson(json);

      expect(model.id, equals("88823510-0b57-470b-92ef-34d9264945a0"));
      expect(model.name, equals("Afuri Harajuku"));
      expect(model.category, equals(1));
    });

    test('fromJson - parses category successfully when it is a String', () {
      final json = {
        "id": "88823510-0b57-470b-92ef-34d9264945a0",
        "tripId": "6a7ec47a19591b12bcbf874c",
        "placeId": "61667572695f686172617261a75",
        "name": "Afuri Harajuku",
        "bookingReference": "",
        "startDatetime": "2026-08-18T09:00:00Z",
        "endDatetime": "2026-08-18T10:00:00Z",
        "currency": "USD",
        "bookingUrl": "",
        "confirmationDocumentUrl": "",
        "activityDetails": {
          "category": "Food",
          "participants": [],
          "meetingPoint": "",
          "duration": 60,
          "difficulty": "Easy",
          "ageRestriction": "None",
          "cost": 0
        }
      };

      final model = TripActivityModel.fromJson(json);

      expect(model.id, equals("88823510-0b57-470b-92ef-34d9264945a0"));
      expect(model.name, equals("Afuri Harajuku"));
      expect(model.category, equals(1)); // Food maps to 1
    });

    test('fromJson - handles unexpected category String gracefully and defaults', () {
      final json = {
        "id": "88823510-0b57-470b-92ef-34d9264945a0",
        "tripId": "6a7ec47a19591b12bcbf874c",
        "placeId": "61667572695f686172617261a75",
        "name": "Afuri Harajuku",
        "bookingReference": "",
        "startDatetime": "2026-08-18T09:00:00Z",
        "endDatetime": "2026-08-18T10:00:00Z",
        "currency": "USD",
        "bookingUrl": "",
        "confirmationDocumentUrl": "",
        "activityDetails": {
          "category": "UnknownCategoryName",
          "participants": [],
          "meetingPoint": "",
          "duration": 60,
          "difficulty": "Easy",
          "ageRestriction": "None",
          "cost": 0
        }
      };

      final model = TripActivityModel.fromJson(json);

      expect(model.category, equals(6)); // Unknown/Other maps to 6
    });
  });
}
