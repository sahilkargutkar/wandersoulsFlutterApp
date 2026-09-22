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
    final depRaw = json['departureDatetime'] ??
        json['DepartureDatetime'] ??
        json['departureDateTime'] ??
        json['departureDate'] ??
        json['departureTime'];
    final departureLocationRaw = json['departureLocation'] ??
        json['DepartureLocation'] ??
        json['from'] ??
        json['departure'] ??
        json['Departure'];
    final parsedDeparture = _extractDateTime(depRaw, departureLocationRaw);

    final arrRaw = json['arrivalDatetime'] ??
        json['ArrivalDatetime'] ??
        json['arrivalDateTime'] ??
        json['arrivalDate'] ??
        json['arrivalTime'];
    final arrivalLocationRaw = json['arrivalLocation'] ??
        json['ArrivalLocation'] ??
        json['to'] ??
        json['arrival'] ??
        json['Arrival'];
    final parsedArrival = _extractDateTime(arrRaw, arrivalLocationRaw);

    final rawCost = json['cost'] ??
        json['Cost'] ??
        json['price'] ??
        json['Price'] ??
        json['amount'] ??
        json['Amount'] ??
        json['fare'] ??
        json['Fare'];
    final double costVal = (rawCost is num)
        ? rawCost.toDouble()
        : (double.tryParse(rawCost?.toString() ?? '') ?? 0.0);

    final id = (json['id'] ?? json['Id'] ?? json['_id'] ?? json['transportId'])?.toString();
    final tripId = (json['tripId'] ?? json['TripId'])?.toString();
    final type = (json['type'] ?? json['Type'] ?? 'Flight').toString();
    final provider = (json['provider'] ??
            json['Provider'] ??
            json['airline'] ??
            json['Airline'] ??
            json['operator'] ??
            json['flightDetails']?['airline'])
        ?.toString();
    final bookingReference = (json['bookingReference'] ??
            json['BookingReference'] ??
            json['reference'] ??
            json['pnr'] ??
            json['PNR'] ??
            json['bookingRef'])
        ?.toString();

    final departureLocation = _parseLocation(departureLocationRaw);
    final arrivalLocation = _parseLocation(arrivalLocationRaw);

    final currency = (json['currency'] ?? json['Currency'] ?? 'USD').toString();
    final seatOrCabin = (json['seatOrCabin'] ??
            json['SeatOrCabin'] ??
            json['seat'] ??
            json['flightDetails']?['seatAssignment'])
        ?.toString();
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

  static String? _parseLocation(dynamic raw) {
    if (raw == null) return null;

    if (raw is Map) {
      final address = (raw['address'] ??
              raw['Address'] ??
              raw['name'] ??
              raw['Name'] ??
              raw['airport'] ??
              raw['station'])
          ?.toString()
          .trim();
      final location = (raw['location'] ??
              raw['Location'] ??
              raw['city'] ??
              raw['City'])
          ?.toString()
          .trim();
      final terminal = (raw['terminal'] ?? raw['Terminal'])?.toString().trim();

      String result = "";
      if (location != null && location.isNotEmpty && address != null && address.isNotEmpty) {
        if (address.toLowerCase().contains(location.toLowerCase())) {
          result = address;
        } else if (location.toLowerCase().contains(address.toLowerCase())) {
          result = location;
        } else {
          result = "$location, $address";
        }
      } else if (address != null && address.isNotEmpty) {
        result = address;
      } else if (location != null && location.isNotEmpty) {
        result = location;
      }

      if (terminal != null &&
          terminal.isNotEmpty &&
          terminal != "0" &&
          terminal != "null") {
        final termStr = terminal.toLowerCase().startsWith("terminal") ||
                terminal.toLowerCase().startsWith("t")
            ? terminal
            : "Terminal $terminal";
        if (!result.toLowerCase().contains("terminal") &&
            !result.toLowerCase().contains("t$terminal")) {
          result = result.isNotEmpty ? "$result ($termStr)" : termStr;
        }
      }

      if (result.isNotEmpty) return result;
    }

    final str = raw.toString().trim();
    if (str.isEmpty) return null;

    // Handle stringified Map like "{location: Singapore, address: Changi Terminal 0, ...}" or text with coordinates/datetime
    if (str.contains("location:") ||
        str.contains("address:") ||
        str.contains("coordinates:") ||
        str.contains("datetime:") ||
        str.startsWith("{")) {
      String? extractedLocation;
      String? extractedAddress;
      String? extractedTerminal;

      final locMatch = RegExp(r'(?:location|city)\s*[:=]\s*([^,}\n]+)', caseSensitive: false)
          .firstMatch(str);
      if (locMatch != null) {
        extractedLocation = locMatch.group(1)?.trim();
      }

      final addrMatch = RegExp(r'(?:address|airport|station|name)\s*[:=]\s*([^,}\n]+)', caseSensitive: false)
          .firstMatch(str);
      if (addrMatch != null) {
        extractedAddress = addrMatch.group(1)?.trim();
      }

      // Check if text exists before coordinates/datetime keys (e.g. "Shivaji International Airport Terminal 2, coordinates: ...")
      if (extractedAddress == null) {
        final firstKeyMatch = RegExp(r'(?:coordinates|datetime|terminal|gate)\s*:', caseSensitive: false)
            .firstMatch(str);
        if (firstKeyMatch != null && firstKeyMatch.start > 0) {
          String prefix = str.substring(0, firstKeyMatch.start).trim();
          if (prefix.startsWith("{")) prefix = prefix.substring(1).trim();
          if (prefix.endsWith(",")) prefix = prefix.substring(0, prefix.length - 1).trim();
          if (prefix.isNotEmpty && !prefix.contains(":")) {
            extractedAddress = prefix;
          }
        }
      }

      final termMatch = RegExp(r'terminal\s*[:=]\s*([^,}\n]+)', caseSensitive: false)
          .firstMatch(str);
      if (termMatch != null) {
        final t = termMatch.group(1)?.trim();
        if (t != null && t != "0" && t != "null" && t.isNotEmpty) {
          extractedTerminal = t;
        }
      }

      String cleaned = "";
      if (extractedLocation != null &&
          extractedLocation.isNotEmpty &&
          extractedAddress != null &&
          extractedAddress.isNotEmpty) {
        if (extractedAddress.toLowerCase().contains(extractedLocation.toLowerCase())) {
          cleaned = extractedAddress;
        } else if (extractedLocation.toLowerCase().contains(extractedAddress.toLowerCase())) {
          cleaned = extractedLocation;
        } else {
          cleaned = "$extractedLocation, $extractedAddress";
        }
      } else if (extractedAddress != null && extractedAddress.isNotEmpty) {
        cleaned = extractedAddress;
      } else if (extractedLocation != null && extractedLocation.isNotEmpty) {
        cleaned = extractedLocation;
      }

      if (extractedTerminal != null && extractedTerminal.isNotEmpty) {
        final termStr = extractedTerminal.toLowerCase().startsWith("terminal") ||
                extractedTerminal.toLowerCase().startsWith("t")
            ? extractedTerminal
            : "Terminal $extractedTerminal";
        if (!cleaned.toLowerCase().contains("terminal") &&
            !cleaned.toLowerCase().contains("t$extractedTerminal")) {
          cleaned = cleaned.isNotEmpty ? "$cleaned ($termStr)" : termStr;
        }
      }

      if (cleaned.isNotEmpty) {
        return cleaned;
      }
    }

    return str;
  }

  static DateTime? _extractDateTime(dynamic raw, dynamic locationRaw) {
    if (raw != null) {
      if (raw is DateTime) return raw;
      final parsed = DateTime.tryParse(raw.toString().trim());
      if (parsed != null) return parsed;
    }

    if (locationRaw != null) {
      if (locationRaw is Map) {
        final dt = locationRaw['datetime'] ??
            locationRaw['dateTime'] ??
            locationRaw['DateTime'] ??
            locationRaw['departureDatetime'] ??
            locationRaw['arrivalDatetime'] ??
            locationRaw['date'] ??
            locationRaw['time'];
        if (dt != null) {
          final parsed = DateTime.tryParse(dt.toString().trim());
          if (parsed != null) return parsed;
        }
      } else if (locationRaw is String) {
        final match = RegExp(r'(?:datetime|date|time)\s*[:=]\s*([0-9T:\-Z\.]+)', caseSensitive: false)
            .firstMatch(locationRaw);
        if (match != null) {
          final parsed = DateTime.tryParse(match.group(1)!.trim());
          if (parsed != null) return parsed;
        }
      }
    }
    return null;
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
