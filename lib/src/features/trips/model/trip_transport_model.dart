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
    DateTime? parsedDeparture;
    final depRaw = json['departureDatetime'] ??
        json['DepartureDatetime'] ??
        json['departureDateTime'] ??
        json['departureDate'] ??
        json['departureTime'];
    if (depRaw != null) {
      parsedDeparture = DateTime.tryParse(depRaw.toString());
    }

    DateTime? parsedArrival;
    final arrRaw = json['arrivalDatetime'] ??
        json['ArrivalDatetime'] ??
        json['arrivalDateTime'] ??
        json['arrivalDate'] ??
        json['arrivalTime'];
    if (arrRaw != null) {
      parsedArrival = DateTime.tryParse(arrRaw.toString());
    }

    final rawCost = json['cost'] ?? json['Cost'] ?? json['price'] ?? json['Price'] ?? json['amount'];
    final double costVal = (rawCost is num)
        ? rawCost.toDouble()
        : (double.tryParse(rawCost?.toString() ?? '') ?? 0.0);

    final id = (json['id'] ?? json['Id'] ?? json['_id'] ?? json['transportId'])?.toString();
    final tripId = (json['tripId'] ?? json['TripId'])?.toString();
    final type = (json['type'] ?? json['Type'] ?? 'Flight').toString();
    final provider = (json['provider'] ?? json['Provider'] ?? json['flightDetails']?['airline'])?.toString();
    final bookingReference = (json['bookingReference'] ?? json['BookingReference'] ?? json['reference'])?.toString();
    final departureLocation = (json['departureLocation'] ?? json['DepartureLocation'] ?? json['from'] ?? json['departure'])?.toString();
    final arrivalLocation = (json['arrivalLocation'] ?? json['ArrivalLocation'] ?? json['to'] ?? json['arrival'])?.toString();
    final currency = (json['currency'] ?? json['Currency'] ?? 'USD').toString();
    final seatOrCabin = (json['seatOrCabin'] ?? json['SeatOrCabin'] ?? json['flightDetails']?['seatAssignment'] ?? json['seat'])?.toString();
    final notes = (json['notes'] ?? json['Notes'] ?? json['description'])?.toString();

    return TripTransportModel(
      id: id,
      tripId: tripId,
      type: type,
      provider: provider,
      bookingReference: bookingReference,
      departureLocation: departureLocation,
      arrivalLocation: arrivalLocation,
      departureDatetime: parsedDeparture,
      arrivalDatetime: parsedArrival,
      cost: costVal,
      currency: currency,
      seatOrCabin: seatOrCabin,
      notes: notes,
    );
  }

  TripTransportModel copyWith({
    String? id,
    String? tripId,
    String? type,
    String? provider,
    String? bookingReference,
    String? departureLocation,
    String? arrivalLocation,
    DateTime? departureDatetime,
    DateTime? arrivalDatetime,
    double? cost,
    String? currency,
    String? seatOrCabin,
    String? notes,
  }) {
    return TripTransportModel(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      type: type ?? this.type,
      provider: provider ?? this.provider,
      bookingReference: bookingReference ?? this.bookingReference,
      departureLocation: departureLocation ?? this.departureLocation,
      arrivalLocation: arrivalLocation ?? this.arrivalLocation,
      departureDatetime: departureDatetime ?? this.departureDatetime,
      arrivalDatetime: arrivalDatetime ?? this.arrivalDatetime,
      cost: cost ?? this.cost,
      currency: currency ?? this.currency,
      seatOrCabin: seatOrCabin ?? this.seatOrCabin,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null && id!.isNotEmpty) "id": id,
      if (tripId != null && tripId!.isNotEmpty) "tripId": tripId,
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
