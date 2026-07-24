import 'package:wonder_souls/src/features/auth/domain/enitiy/trip_day.dart';

class TripDayModel extends TripDay {
  const TripDayModel({
    required super.dayId,
    required super.date,
    super.notes,
    super.scheduledPlaces,
  });

  /// FROM JSON
  factory TripDayModel.fromJson(Map<String, dynamic> json) {
    return TripDayModel(
      dayId: json['dayId']?['timestamp'] != null
          ? json['dayId']['timestamp'].toString()
          : json['dayId']?.toString() ?? '',
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      notes: json['notes'],
      scheduledPlaces: json['scheduledPlaces'] != null
          ? List<String>.from(json['scheduledPlaces'])
          : null,
    );
  }

  /// TO JSON
  Map<String, dynamic> toJson() {
    return {
      "dayId": dayId,
      "date": date.toIso8601String(),
      "notes": notes,
      "scheduledPlaces": scheduledPlaces,
    };
  }
}
