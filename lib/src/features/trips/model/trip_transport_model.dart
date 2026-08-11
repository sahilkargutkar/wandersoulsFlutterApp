class TripTransportModel {
  final String? id;
  final String? tripId;
  final String type; // Flight, Train, Bus, Car, Ferry
  final String? provider;
  final String? bookingReference;
  final String? departureLocation;
  final String? arrivalLocation;
  final DateTime? departureDatetime;
  final DateTime? arrivalDatetime;
  final double cost;
  final String? currency;
  final String? seatOrCabin;
  final String? notes;

  TripTransportModel({
    this.id,
    this.tripId,
    required this.type,
    this.provider,
    this.bookingReference,
    this.departureLocation,
    this.arrivalLocation,
    this.departureDatetime,
    this.arrivalDatetime,
    this.cost = 0.0,
    this.currency = "USD",
    this.seatOrCabin,
    this.notes,
  });

  factory TripTransportModel.fromJson(Map<String, dynamic> json) {
    return TripTransportModel(
      id: json['id'],
      tripId: json['tripId'],
      type: json['type'] ?? 'Flight',
      provider: json['provider'] ?? json['flightDetails']?['airline'],
      bookingReference: json['bookingReference'],
      departureLocation: json['departureLocation'],
      arrivalLocation: json['arrivalLocation'],
      departureDatetime: json['departureDatetime'] != null
          ? DateTime.tryParse(json['departureDatetime'])
          : null,
      arrivalDatetime: json['arrivalDatetime'] != null
          ? DateTime.tryParse(json['arrivalDatetime'])
          : null,
      cost: (json['cost'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'],
      seatOrCabin:
          json['seatOrCabin'] ?? json['flightDetails']?['seatAssignment'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) "id": id,
      if (tripId != null) "tripId": tripId,
      "type": type,
      "provider": provider ?? "",
      "bookingReference": bookingReference ?? "",
      "departureLocation": departureLocation ?? "",
      "arrivalLocation": arrivalLocation ?? "",
      "departureDatetime": (departureDatetime ?? DateTime.now())
          .toUtc()
          .toIso8601String(),
      "arrivalDatetime":
          (arrivalDatetime ?? DateTime.now().add(const Duration(hours: 2)))
              .toUtc()
              .toIso8601String(),
      "cost": cost,
      "currency": currency ?? "USD",
      "seatOrCabin": seatOrCabin ?? "",
      "notes": notes ?? "",
    };
  }
}
