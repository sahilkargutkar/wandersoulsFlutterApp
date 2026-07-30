class TripActivityModel {
  final String id;
  final String tripId;
  final String placeId;
  final String dayId;
  final String name;
  final String? bookingReference;
  final DateTime startDatetime;
  final DateTime endDatetime;
  final String? currency;
  final String? bookingUrl;
  final String? confirmationDocumentUrl;
  final String? notes;
  final int category; // categoryDto
  final double cost;
  final String? tips;
  final String? imageUrl;

  TripActivityModel({
    required this.id,
    required this.tripId,
    required this.placeId,
    required this.dayId,
    required this.name,
    this.bookingReference,
    required this.startDatetime,
    required this.endDatetime,
    this.currency,
    this.bookingUrl,
    this.confirmationDocumentUrl,
    this.notes,
    required this.category,
    required this.cost,
    this.tips,
    this.imageUrl,
  });

  factory TripActivityModel.fromJson(Map<String, dynamic> json) {
    final details = (json['activityDetails'] ?? json['activityDetailsDto']) as Map<String, dynamic>?;
    return TripActivityModel(
      id: json['id'] ?? '',
      tripId: json['tripId'] ?? '',
      placeId: json['placeId'] ?? '',
      dayId: json['dayId'] ?? '',
      name: json['name'] ?? '',
      bookingReference: json['bookingReference'],
      startDatetime: DateTime.tryParse(json['startDatetime'] ?? '') ?? DateTime.now(),
      endDatetime: DateTime.tryParse(json['endDatetime'] ?? '') ?? DateTime.now(),
      currency: json['currency'],
      bookingUrl: json['bookingUrl'],
      confirmationDocumentUrl: json['confirmationDocumentUrl'],
      notes: json['notes'],
      category: details?['category'] ?? details?['categoryDto'] ?? 0,
      cost: (details?['cost'] as num?)?.toDouble() ?? 0.0,
      tips: details?['tips'],
      imageUrl: details?['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "tripId": tripId,
      "placeId": placeId,
      "dayId": dayId,
      "name": name,
      "bookingReference": bookingReference,
      "startDatetime": startDatetime.toUtc().toIso8601String(),
      "endDatetime": endDatetime.toUtc().toIso8601String(),
      "currency": currency,
      "bookingUrl": bookingUrl,
      "confirmationDocumentUrl": confirmationDocumentUrl,
      "notes": notes,
      "activityDetailsDto": {
        "categoryDto": category,
        "participants": [],
        "meetingPoint": "",
        "duration": 0,
        "difficulty": "",
        "ageRestriction": "",
        "cost": cost,
        "tips": tips,
        "imageUrl": imageUrl
      }
    };
  }
}
