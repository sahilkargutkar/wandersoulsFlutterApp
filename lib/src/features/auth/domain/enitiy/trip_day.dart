import 'package:equatable/equatable.dart';

class TripDay extends Equatable {
  final String dayId;
  final DateTime date;
  final String? notes;
  final List<String>? scheduledPlaces;

  const TripDay({
    required this.dayId,
    required this.date,
    this.notes,
    this.scheduledPlaces,
  });

  @override
  List<Object?> get props => [dayId, date, notes, scheduledPlaces];
}
