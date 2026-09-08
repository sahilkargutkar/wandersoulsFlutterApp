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

    final rawImageUrl = details?['imageUrl'] ??
        details?['image'] ??
        details?['photoUrl'] ??
        details?['photo'] ??
        json['imageUrl'] ??
        json['image'] ??
        json['photoUrl'] ??
        json['photo'];

    String? parsedImageUrl;
    if (rawImageUrl != null) {
      final str = rawImageUrl.toString().trim();
      if (str.startsWith('http://') || str.startsWith('https://')) {
        parsedImageUrl = str;
      }
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
      imageUrl: parsedImageUrl,
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

  String get displayImageUrl {
    if (imageUrl != null &&
        imageUrl!.trim().isNotEmpty &&
        (imageUrl!.startsWith('http://') || imageUrl!.startsWith('https://'))) {
      return imageUrl!;
    }
    return getFallbackImage(category, name);
  }

  static String getFallbackImage(int category, [String? name]) {
    if (name != null && name.trim().isNotEmpty) {
      final nameLower = name.toLowerCase();
      if (nameLower.contains("mosque") ||
          nameLower.contains("qaboos") ||
          nameLower.contains("masjid") ||
          nameLower.contains("islamic")) {
        return "https://images.unsplash.com/photo-1548013146-72479768bada?w=800";
      }
      if (nameLower.contains("souq") ||
          nameLower.contains("souk") ||
          nameLower.contains("mutrah") ||
          nameLower.contains("bazaar") ||
          nameLower.contains("market")) {
        return "https://images.unsplash.com/photo-1563245372-f21724e3856d?w=800";
      }
      if (nameLower.contains("wadi") ||
          nameLower.contains("sinkhole") ||
          nameLower.contains("bimmah") ||
          nameLower.contains("shab") ||
          nameLower.contains("canyon") ||
          nameLower.contains("gorge")) {
        return "https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=800";
      }
      if (nameLower.contains("opera") ||
          nameLower.contains("theater") ||
          nameLower.contains("theatre") ||
          nameLower.contains("concert")) {
        return "https://images.unsplash.com/photo-1514306191717-452ec28c7814?w=800";
      }
      if (nameLower.contains("palace") ||
          nameLower.contains("castle") ||
          nameLower.contains("fort") ||
          nameLower.contains("alam") ||
          nameLower.contains("jalali") ||
          nameLower.contains("mirani") ||
          nameLower.contains("monument")) {
        return "https://images.unsplash.com/photo-1590725140246-20acceedafe1?w=800";
      }
      if (nameLower.contains("eiffel") ||
          nameLower.contains("tower") ||
          nameLower.contains("burj") ||
          nameLower.contains("khalifa") ||
          nameLower.contains("skyscraper") ||
          nameLower.contains("viewpoint") ||
          nameLower.contains("observation") ||
          nameLower.contains("sky")) {
        return "https://images.unsplash.com/photo-1502602898657-3e91760cbb34?w=800";
      }
      if (nameLower.contains("louvre") ||
          nameLower.contains("museum") ||
          nameLower.contains("art") ||
          nameLower.contains("gallery") ||
          nameLower.contains("exhibition") ||
          nameLower.contains("zubair")) {
        return "https://images.unsplash.com/photo-1566127444979-b3d2b654e3d7?w=800";
      }
      if (nameLower.contains("shrine") ||
          nameLower.contains("temple") ||
          nameLower.contains("senso") ||
          nameLower.contains("asakusa") ||
          nameLower.contains("meiji") ||
          nameLower.contains("jingu") ||
          nameLower.contains("pagoda") ||
          nameLower.contains("sanctuary")) {
        return "https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?w=800";
      }
      if (nameLower.contains("shibuya") ||
          nameLower.contains("crossing") ||
          nameLower.contains("hachiko") ||
          nameLower.contains("times square") ||
          nameLower.contains("street") ||
          nameLower.contains("city")) {
        return "https://images.unsplash.com/photo-1503899036084-c55cdd92da26?w=800";
      }
      if (nameLower.contains("safari") ||
          nameLower.contains("desert") ||
          nameLower.contains("dune") ||
          nameLower.contains("camel") ||
          nameLower.contains("bedouin") ||
          nameLower.contains("camp")) {
        return "https://images.unsplash.com/photo-1509316975850-ff9c5deb0cd9?w=800";
      }
      if (nameLower.contains("cruise") ||
          nameLower.contains("boat") ||
          nameLower.contains("abra") ||
          nameLower.contains("ferry") ||
          nameLower.contains("seine") ||
          nameLower.contains("river") ||
          nameLower.contains("creek")) {
        return "https://images.unsplash.com/photo-1500382017468-9049fed747ef?w=800";
      }
      if (nameLower.contains("beach") ||
          nameLower.contains("coast") ||
          nameLower.contains("sea") ||
          nameLower.contains("ocean") ||
          nameLower.contains("island") ||
          nameLower.contains("corniche") ||
          nameLower.contains("surf")) {
        return "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800";
      }
      if (nameLower.contains("park") ||
          nameLower.contains("garden") ||
          nameLower.contains("botanical") ||
          nameLower.contains("yoyogi") ||
          nameLower.contains("zoo") ||
          nameLower.contains("nature")) {
        return "https://images.unsplash.com/photo-1519331379826-f10be5486c6f?w=800";
      }
      if (nameLower.contains("mountain") ||
          nameLower.contains("hike") ||
          nameLower.contains("hiking") ||
          nameLower.contains("trek") ||
          nameLower.contains("trail") ||
          nameLower.contains("peak") ||
          nameLower.contains("hill") ||
          nameLower.contains("alps")) {
        return "https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=800";
      }
      if (nameLower.contains("lake") ||
          nameLower.contains("dam") ||
          nameLower.contains("waterfall") ||
          nameLower.contains("fountain") ||
          nameLower.contains("kundala") ||
          nameLower.contains("mattupetty")) {
        return "https://images.unsplash.com/photo-1439853941329-a9f1a9a835b0?w=800";
      }
      if (nameLower.contains("ramen") ||
          nameLower.contains("noodle") ||
          nameLower.contains("pasta") ||
          nameLower.contains("sushi") ||
          nameLower.contains("japanese")) {
        return "https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=800";
      }
      if (nameLower.contains("cafe") ||
          nameLower.contains("coffee") ||
          nameLower.contains("bakery") ||
          nameLower.contains("breakfast") ||
          nameLower.contains("tea")) {
        return "https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=800";
      }
      if (nameLower.contains("restaurant") ||
          nameLower.contains("dining") ||
          nameLower.contains("dinner") ||
          nameLower.contains("food") ||
          nameLower.contains("tasting") ||
          nameLower.contains("bistro") ||
          nameLower.contains("grill") ||
          nameLower.contains("bar") ||
          nameLower.contains("pub")) {
        return "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800";
      }
      if (nameLower.contains("hotel") ||
          nameLower.contains("resort") ||
          nameLower.contains("stay") ||
          nameLower.contains("villa") ||
          nameLower.contains("hostel") ||
          nameLower.contains("lodge")) {
        return "https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800";
      }
      if (nameLower.contains("spa") ||
          nameLower.contains("onsen") ||
          nameLower.contains("sauna") ||
          nameLower.contains("wellness") ||
          nameLower.contains("massage") ||
          nameLower.contains("relaxation")) {
        return "https://images.unsplash.com/photo-1540555700478-4be289fbecef?w=800";
      }
      if (nameLower.contains("shopping") ||
          nameLower.contains("mall") ||
          nameLower.contains("store") ||
          nameLower.contains("shop")) {
        return "https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=800";
      }
      if (nameLower.contains("airport") ||
          nameLower.contains("flight") ||
          nameLower.contains("train") ||
          nameLower.contains("station") ||
          nameLower.contains("bus") ||
          nameLower.contains("transport")) {
        return "https://images.unsplash.com/photo-1436491865332-7a61a109cc05?w=800";
      }
    }

    switch (category) {
      case 1: // Food & Dining
        return "https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800";
      case 2: // Transport
        return "https://images.unsplash.com/photo-1436491865332-7a61a109cc05?w=800";
      case 3: // Accommodation
        return "https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800";
      case 4: // Relaxation
        return "https://images.unsplash.com/photo-1540555700478-4be289fbecef?w=800";
      case 5: // Shopping
        return "https://images.unsplash.com/photo-1483985988355-763728e1935b?w=800";
      case 0: // Tourist Attraction / Landmark
        return "https://images.unsplash.com/photo-1488646953014-85cb44e25828?w=800";
      case 6: // General Activity
      default:
        return "https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?w=800";
    }
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
