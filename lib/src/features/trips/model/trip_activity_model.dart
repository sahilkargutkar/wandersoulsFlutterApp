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
    final details =
        (json['activityDetails'] ?? json['activityDetailsDto'])
            as Map<String, dynamic>?;
    final rawCategory = details?['category'] ?? details?['categoryDto'];
    final int categoryVal;
    if (rawCategory is int) {
      categoryVal = rawCategory;
    } else if (rawCategory is String) {
      final parsed = int.tryParse(rawCategory);
      if (parsed != null) {
        categoryVal = parsed;
      } else if (rawCategory.toLowerCase() == 'food') {
        categoryVal = 1;
      } else {
        categoryVal = 6;
      }
    } else {
      categoryVal = 0;
    }

    return TripActivityModel(
      id: _parseId(json['id']),
      tripId: _parseId(json['tripId']),
      placeId: _parseId(json['placeId']),
      dayId: json['dayId'] ?? '',
      name: json['name'] ?? '',
      bookingReference: json['bookingReference'],
      startDatetime:
          DateTime.tryParse(json['startDatetime'] ?? '') ?? DateTime.now(),
      endDatetime:
          DateTime.tryParse(json['endDatetime'] ?? '') ?? DateTime.now(),
      currency: json['currency'],
      bookingUrl: json['bookingUrl'],
      confirmationDocumentUrl: json['confirmationDocumentUrl'],
      notes: json['notes'],
      category: categoryVal,
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
      "activityDetails": {
        "category": category,
        "cost": cost,
        "tips": tips,
        "imageUrl": imageUrl,
      },
    };
  }

  TripActivityModel copyWith({
    String? id,
    String? tripId,
    String? placeId,
    String? dayId,
    String? name,
    String? bookingReference,
    DateTime? startDatetime,
    DateTime? endDatetime,
    String? currency,
    String? bookingUrl,
    String? confirmationDocumentUrl,
    String? notes,
    int? category,
    double? cost,
    String? tips,
    String? imageUrl,
  }) {
    return TripActivityModel(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      placeId: placeId ?? this.placeId,
      dayId: dayId ?? this.dayId,
      name: name ?? this.name,
      bookingReference: bookingReference ?? this.bookingReference,
      startDatetime: startDatetime ?? this.startDatetime,
      endDatetime: endDatetime ?? this.endDatetime,
      currency: currency ?? this.currency,
      bookingUrl: bookingUrl ?? this.bookingUrl,
      confirmationDocumentUrl: confirmationDocumentUrl ?? this.confirmationDocumentUrl,
      notes: notes ?? this.notes,
      category: category ?? this.category,
      cost: cost ?? this.cost,
      tips: tips ?? this.tips,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}

String _parseId(dynamic jsonVal) {
  if (jsonVal is String) {
    return jsonVal;
  }
  if (jsonVal is Map<String, dynamic>) {
    return (jsonVal["\$oid"] ?? jsonVal["oid"] ?? "").toString();
  }
  return (jsonVal ?? "").toString();
}
