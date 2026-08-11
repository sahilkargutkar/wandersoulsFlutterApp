class AccommodationModel {
  final String? id;
  final String? tripId;
  final String name;
  final String? type;
  final String? bookingReference;
  final String? address;
  final DateTime? checkInDate;
  final String? checkInInstructions;
  final DateTime? checkOutDate;
  final String? checkOutInstructions;
  final double cost;
  final String? currency;
  final String? bookingUrl;
  final String? confirmationDocumentUrl;
  final String? phone;
  final String? notes;

  AccommodationModel({
    this.id,
    this.tripId,
    required this.name,
    this.type,
    this.bookingReference,
    this.address,
    this.checkInDate,
    this.checkInInstructions,
    this.checkOutDate,
    this.checkOutInstructions,
    this.cost = 0.0,
    this.currency = "USD",
    this.bookingUrl,
    this.confirmationDocumentUrl,
    this.phone,
    this.notes,
  });

  factory AccommodationModel.fromJson(Map<String, dynamic> json) {
    final checkIn = json['checkIn'] as Map<String, dynamic>?;
    final checkOut = json['checkOut'] as Map<String, dynamic>?;

    return AccommodationModel(
      id: json['id'],
      tripId: json['tripId'],
      name: json['name'] ?? '',
      type: json['type'],
      bookingReference: json['bookingReference'],
      address: json['address'],
      checkInDate: checkIn?['datetime'] != null
          ? DateTime.tryParse(checkIn!['datetime'])
          : null,
      checkInInstructions: checkIn?['instructions'],
      checkOutDate: checkOut?['datetime'] != null
          ? DateTime.tryParse(checkOut!['datetime'])
          : null,
      checkOutInstructions: checkOut?['instructions'],
      cost: (json['cost'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'],
      bookingUrl: json['bookingUrl'],
      confirmationDocumentUrl: json['confirmationDocumentUrl'],
      phone: json['phone'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) "id": id,
      if (tripId != null) "tripId": tripId,
      "name": name,
      "type": type ?? "Hotel",
      "bookingReference": bookingReference ?? "",
      "address": address ?? "",
      "checkIn": {
        "datetime": (checkInDate ?? DateTime.now()).toUtc().toIso8601String(),
        "instructions": checkInInstructions ?? "",
      },
      "checkOut": {
        "datetime": (checkOutDate ?? DateTime.now().add(const Duration(days: 1))).toUtc().toIso8601String(),
        "instructions": checkOutInstructions ?? "",
      },
      "cost": cost,
      "currency": currency ?? "USD",
      "bookingUrl": bookingUrl ?? "",
      "confirmationDocumentUrl": confirmationDocumentUrl ?? "",
      "phone": phone ?? "",
      "notes": notes ?? "",
    };
  }
}
