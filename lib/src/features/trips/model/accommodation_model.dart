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
    DateTime? parsedCheckInDate;
    String? parsedCheckInInstructions;
    DateTime? parsedCheckOutDate;
    String? parsedCheckOutInstructions;

    final rawCheckIn = json['checkIn'] ?? json['CheckIn'];
    if (rawCheckIn is Map<String, dynamic>) {
      final dt = rawCheckIn['datetime'] ?? rawCheckIn['dateTime'] ?? rawCheckIn['date'];
      if (dt != null) {
        parsedCheckInDate = DateTime.tryParse(dt.toString());
      }
      parsedCheckInInstructions = (rawCheckIn['instructions'] ?? rawCheckIn['Instructions'])?.toString();
    } else if (rawCheckIn is String && rawCheckIn.isNotEmpty) {
      parsedCheckInDate = DateTime.tryParse(rawCheckIn);
    }

    if (parsedCheckInDate == null) {
      final flatCheckIn = json['checkInDate'] ?? json['CheckInDate'] ?? json['checkInDatetime'] ?? json['checkInDateTime'];
      if (flatCheckIn != null) {
        parsedCheckInDate = DateTime.tryParse(flatCheckIn.toString());
      }
    }
    if (parsedCheckInInstructions == null && json['checkInInstructions'] != null) {
      parsedCheckInInstructions = json['checkInInstructions'].toString();
    }

    final rawCheckOut = json['checkOut'] ?? json['CheckOut'];
    if (rawCheckOut is Map<String, dynamic>) {
      final dt = rawCheckOut['datetime'] ?? rawCheckOut['dateTime'] ?? rawCheckOut['date'];
      if (dt != null) {
        parsedCheckOutDate = DateTime.tryParse(dt.toString());
      }
      parsedCheckOutInstructions = (rawCheckOut['instructions'] ?? rawCheckOut['Instructions'])?.toString();
    } else if (rawCheckOut is String && rawCheckOut.isNotEmpty) {
      parsedCheckOutDate = DateTime.tryParse(rawCheckOut);
    }

    if (parsedCheckOutDate == null) {
      final flatCheckOut = json['checkOutDate'] ?? json['CheckOutDate'] ?? json['checkOutDatetime'] ?? json['checkOutDateTime'];
      if (flatCheckOut != null) {
        parsedCheckOutDate = DateTime.tryParse(flatCheckOut.toString());
      }
    }
    if (parsedCheckOutInstructions == null && json['checkOutInstructions'] != null) {
      parsedCheckOutInstructions = json['checkOutInstructions'].toString();
    }

    final rawCost = json['cost'] ?? json['Cost'] ?? json['price'] ?? json['Price'] ?? json['amount'];
    final double costVal = (rawCost is num)
        ? rawCost.toDouble()
        : (double.tryParse(rawCost?.toString() ?? '') ?? 0.0);

    final id = (json['id'] ?? json['Id'] ?? json['_id'] ?? json['accommodationId'])?.toString();
    final tripId = (json['tripId'] ?? json['TripId'])?.toString();
    final name = (json['name'] ?? json['Name'] ?? json['title'] ?? '').toString();
    final type = (json['type'] ?? json['Type'])?.toString();
    final bookingReference = (json['bookingReference'] ?? json['BookingReference'] ?? json['reference'])?.toString();
    final address = (json['address'] ?? json['Address'] ?? json['location'])?.toString();
    final currency = (json['currency'] ?? json['Currency'] ?? 'USD').toString();
    final bookingUrl = (json['bookingUrl'] ?? json['BookingUrl'])?.toString();
    final confirmationDocumentUrl = (json['confirmationDocumentUrl'] ?? json['ConfirmationDocumentUrl'])?.toString();
    final phone = (json['phone'] ?? json['Phone'])?.toString();
    final notes = (json['notes'] ?? json['Notes'] ?? json['description'])?.toString();

    return AccommodationModel(
      id: id,
      tripId: tripId,
      name: name,
      type: type,
      bookingReference: bookingReference,
      address: address,
      checkInDate: parsedCheckInDate,
      checkInInstructions: parsedCheckInInstructions,
      checkOutDate: parsedCheckOutDate,
      checkOutInstructions: parsedCheckOutInstructions,
      cost: costVal,
      currency: currency,
      bookingUrl: bookingUrl,
      confirmationDocumentUrl: confirmationDocumentUrl,
      phone: phone,
      notes: notes,
    );
  }

  AccommodationModel copyWith({
    String? id,
    String? tripId,
    String? name,
    String? type,
    String? bookingReference,
    String? address,
    DateTime? checkInDate,
    String? checkInInstructions,
    DateTime? checkOutDate,
    String? checkOutInstructions,
    double? cost,
    String? currency,
    String? bookingUrl,
    String? confirmationDocumentUrl,
    String? phone,
    String? notes,
  }) {
    return AccommodationModel(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      name: name ?? this.name,
      type: type ?? this.type,
      bookingReference: bookingReference ?? this.bookingReference,
      address: address ?? this.address,
      checkInDate: checkInDate ?? this.checkInDate,
      checkInInstructions: checkInInstructions ?? this.checkInInstructions,
      checkOutDate: checkOutDate ?? this.checkOutDate,
      checkOutInstructions: checkOutInstructions ?? this.checkOutInstructions,
      cost: cost ?? this.cost,
      currency: currency ?? this.currency,
      bookingUrl: bookingUrl ?? this.bookingUrl,
      confirmationDocumentUrl: confirmationDocumentUrl ?? this.confirmationDocumentUrl,
      phone: phone ?? this.phone,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null && id!.isNotEmpty) "id": id,
      if (tripId != null && tripId!.isNotEmpty) "tripId": tripId,
      "name": name,
      "type": type ?? "Hotel",
      "bookingReference": bookingReference ?? "",
      "address": address ?? "",
      "checkIn": {
        "datetime": (checkInDate ?? DateTime.now()).toUtc().toIso8601String(),
        "instructions": checkInInstructions ?? "",
      },
      "checkOut": {
        "datetime":
            (checkOutDate ?? DateTime.now().add(const Duration(days: 1)))
                .toUtc()
                .toIso8601String(),
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
