class Trip {
  final String id;
  final String name;
  final String location;
  final String country;
  final String imageUrl;
  final String startDate;
  final String endDate;
  final int days;
  final List<Place> places;

  Trip({
    required this.id,
    required this.name,
    required this.location,
    required this.country,
    required this.imageUrl,
    required this.startDate,
    required this.endDate,
    required this.days,
    required this.places,
  });
}

class Place {
  final String id;
  final String name;
  final String imageUrl;
  final double rating;
  final int reviews;
  final String openTime;
  final String closeTime;
  final double price;
  final String category;
  final List<String> activities;

  Place({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.rating,
    required this.reviews,
    required this.openTime,
    required this.closeTime,
    required this.price,
    required this.category,
    required this.activities,
  });
}

final Trip sampleTrip = Trip(
  id: 'trip_001',
  name: 'Tokyo Explorer',
  location: 'Tokyo',
  country: 'Japan',
  imageUrl:
      'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?w=800',
  startDate: '2024-03-10',
  endDate: '2024-03-15',
  days: 5,
  places: [
    Place(
      id: 'place_001',
      name: 'Tokyo Tower',
      imageUrl:
          'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?w=800',
      rating: 4.6,
      reviews: 18542,
      openTime: '09:00 AM',
      closeTime: '11:00 PM',
      price: 25.0,
      category: 'Landmark',
      activities: [
        'Observation Deck',
        'City View Photography',
        'Souvenir Shopping',
      ],
    ),
    Place(
      id: 'place_002',
      name: 'Shibuya Crossing',
      imageUrl:
          'https://images.unsplash.com/photo-1503899036084-c55cdd92da26?w=800',
      rating: 4.8,
      reviews: 32110,
      openTime: 'Open 24 Hours',
      closeTime: 'Open 24 Hours',
      price: 0.0,
      category: 'City Experience',
      activities: ['Street Photography', 'People Watching', 'Shopping'],
    ),
  ],
);

class TripData {
  final String id;
  final String name;
  final String description;
  final String flag;
  final String dateRange;
  final String tripType;
  final String category;
  final String imageUrl;
  final DateTime? startDate;
  final DateTime? endDate;
  final String mainDestination;
  final List<String> travelTastes;
  final double totalBudget;
  final String currency;
  final double transportBudget;
  final double accommodationBudget;
  final double foodBudget;
  final double activitiesBudget;

  TripData({
    required this.id,
    required this.name,
    required this.description,
    required this.flag,
    required this.dateRange,
    required this.tripType,
    required this.category,
    required this.imageUrl,
    this.startDate,
    this.endDate,
    required this.mainDestination,
    required this.travelTastes,
    this.totalBudget = 0.0,
    this.currency = "USD",
    this.transportBudget = 0.0,
    this.accommodationBudget = 0.0,
    this.foodBudget = 0.0,
    this.activitiesBudget = 0.0,
  });

  factory TripData.fromJson(Map<String, dynamic> jsonMap) {
    final id = _parseId(jsonMap["id"] ?? jsonMap["_id"] ?? jsonMap["tripId"]);
    final mainDest = (jsonMap["mainDestination"] ??
            jsonMap["destination"] ??
            jsonMap["location"] ??
            "")
        .toString();
    final rawName =
        jsonMap["name"] ?? jsonMap["tripName"] ?? jsonMap["title"];
    final name = (rawName != null && rawName.toString().isNotEmpty)
        ? rawName.toString()
        : (mainDest.isNotEmpty ? "Trip to $mainDest" : "My Trip");
    final description =
        (jsonMap["description"] ?? jsonMap["desc"] ?? "").toString();
    final flag = _getCountryFlag(mainDest);

    DateTime? start;
    DateTime? end;
    if (jsonMap["startDate"] != null) {
      start = DateTime.tryParse(jsonMap["startDate"].toString());
    }
    if (jsonMap["endDate"] != null) {
      end = DateTime.tryParse(jsonMap["endDate"].toString());
    }

    final dateRange = _formatDateRange(start, end);
    final whoIsGoing = _capitalize(
        (jsonMap["whoIsGoing"] ?? jsonMap["partyType"] ?? "solo").toString());

    // Budget parsing
    String budgetLevelStr = "flexible";
    double totalEstimated = 0.0;
    String currencyStr = "USD";
    double transportBudget = 0.0;
    double accommodationBudget = 0.0;
    double foodBudget = 0.0;
    double activitiesBudget = 0.0;

    final rawBudget = jsonMap["budget"];
    if (rawBudget is Map<String, dynamic>) {
      budgetLevelStr = (rawBudget["budgetType"] ??
              rawBudget["type"] ??
              jsonMap["budgetType"] ??
              "flexible")
          .toString();
      totalEstimated = (rawBudget["totalEstimated"] as num?)?.toDouble() ??
          (rawBudget["total"] as num?)?.toDouble() ??
          (jsonMap["totalBudget"] as num?)?.toDouble() ??
          0.0;
      currencyStr = (rawBudget["currency"] ?? jsonMap["currency"] ?? "USD")
          .toString();

      final byCat = rawBudget["byCategory"];
      if (byCat is Map<String, dynamic>) {
        transportBudget =
            (byCat["transportation"] as num?)?.toDouble() ??
            (byCat["transport"] as num?)?.toDouble() ??
            0.0;
        accommodationBudget =
            (byCat["accommodation"] as num?)?.toDouble() ?? 0.0;
        foodBudget = (byCat["food"] as num?)?.toDouble() ?? 0.0;
        activitiesBudget =
            (byCat["activities"] as num?)?.toDouble() ?? 0.0;
      }
    } else if (rawBudget is String) {
      budgetLevelStr = rawBudget;
    } else if (jsonMap["budgetType"] != null) {
      budgetLevelStr = jsonMap["budgetType"].toString();
    }

    final budgetLevel = _capitalize(budgetLevelStr);

    dynamic rawImageUrl = jsonMap["imageUrl"] ??
        jsonMap["image"] ??
        jsonMap["coverImage"] ??
        jsonMap["thumbnailUrl"] ??
        jsonMap["photoUrl"] ??
        jsonMap["photo"];

    if ((rawImageUrl == null || rawImageUrl.toString().isEmpty)) {
      if (jsonMap["destination"] is Map<String, dynamic>) {
        final destMap = jsonMap["destination"] as Map<String, dynamic>;
        rawImageUrl = destMap["imageUrl"] ?? destMap["image"] ?? destMap["photo"];
      } else if (jsonMap["destinations"] is List &&
          (jsonMap["destinations"] as List).isNotEmpty) {
        final firstDest = (jsonMap["destinations"] as List).first;
        if (firstDest is Map<String, dynamic>) {
          rawImageUrl =
              firstDest["imageUrl"] ?? firstDest["image"] ?? firstDest["photo"];
        }
      }
    }

    final rawStr = rawImageUrl?.toString().trim() ?? "";
    final isValidUrl = rawStr.startsWith("http://") || rawStr.startsWith("https://");
    final imageUrl = isValidUrl
        ? rawStr
        : getTripImage(mainDest.isNotEmpty ? mainDest : name);

    List<String> travelTastes = [];
    final rawTastes = jsonMap["travelTastes"] ??
        jsonMap["interests"] ??
        jsonMap["tastes"];
    if (rawTastes is List) {
      travelTastes = rawTastes.map((e) => e.toString()).toList();
    } else if (rawTastes is String && rawTastes.isNotEmpty) {
      travelTastes = rawTastes.split(',').map((e) => e.trim()).toList();
    }

    return TripData(
      id: id,
      name: name,
      description: description,
      flag: flag,
      dateRange: dateRange,
      tripType: whoIsGoing,
      category: budgetLevel,
      imageUrl: imageUrl,
      startDate: start,
      endDate: end,
      mainDestination: mainDest,
      travelTastes: travelTastes,
      totalBudget: totalEstimated,
      currency: currencyStr,
      transportBudget: transportBudget,
      accommodationBudget: accommodationBudget,
      foodBudget: foodBudget,
      activitiesBudget: activitiesBudget,
    );
  }

  TripData copyWith({
    String? id,
    String? name,
    String? description,
    String? flag,
    String? dateRange,
    String? tripType,
    String? category,
    String? imageUrl,
    DateTime? startDate,
    DateTime? endDate,
    String? mainDestination,
    List<String>? travelTastes,
    double? totalBudget,
    String? currency,
    double? transportBudget,
    double? accommodationBudget,
    double? foodBudget,
    double? activitiesBudget,
  }) {
    return TripData(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      flag: flag ?? this.flag,
      dateRange: dateRange ?? this.dateRange,
      tripType: tripType ?? this.tripType,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      mainDestination: mainDestination ?? this.mainDestination,
      travelTastes: travelTastes ?? this.travelTastes,
      totalBudget: totalBudget ?? this.totalBudget,
      currency: currency ?? this.currency,
      transportBudget: transportBudget ?? this.transportBudget,
      accommodationBudget: accommodationBudget ?? this.accommodationBudget,
      foodBudget: foodBudget ?? this.foodBudget,
      activitiesBudget: activitiesBudget ?? this.activitiesBudget,
    );
  }

  static String _formatDateRange(DateTime? start, DateTime? end) {
    if (start == null || end == null) return "Dates Unknown";
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return "${start.day} ${months[start.month - 1]} - ${end.day} ${months[end.month - 1]}";
  }

  static bool _matchesDestination(String dest, List<String> keywords) {
    final lower = dest.toLowerCase();
    for (final kw in keywords) {
      if (kw.length <= 3) {
        if (RegExp(r'\b' + RegExp.escape(kw) + r'\b').hasMatch(lower)) {
          return true;
        }
      } else {
        if (lower.contains(kw)) return true;
      }
    }
    return false;
  }

  static String _getCountryFlag(String destination) {
    if (_matchesDestination(destination, ["thailand", "phuket", "bangkok", "chiang mai", "pattaya", "krabi", "koh samui"])) {
      return "🇹🇭";
    }
    if (_matchesDestination(destination, ["tokyo", "japan", "osaka", "kyoto", "fukuoka", "sapporo"])) {
      return "🇯🇵";
    }
    if (_matchesDestination(destination, ["paris", "france", "nice", "lyon", "marseille"])) {
      return "🇫🇷";
    }
    if (_matchesDestination(destination, ["london", "uk", "united kingdom", "england", "scotland", "wales", "manchester"])) {
      return "🇬🇧";
    }
    if (_matchesDestination(destination, ["rome", "italy", "milan", "florence", "venice", "naples"])) {
      return "🇮🇹";
    }
    if (_matchesDestination(destination, ["muscat", "oman", "salalah", "nizwa"])) {
      return "🇴🇲";
    }
    if (_matchesDestination(destination, ["new york", "usa", "us", "united states", "california", "los angeles", "san francisco", "miami", "chicago", "vegas"])) {
      return "🇺🇸";
    }
    if (_matchesDestination(destination, ["sydney", "australia", "melbourne", "brisbane", "perth"])) {
      return "🇦🇺";
    }
    if (_matchesDestination(destination, ["delhi", "india", "mumbai", "bangalore", "goa", "jaipur", "munnar", "kerala", "agra"])) {
      return "🇮🇳";
    }
    if (_matchesDestination(destination, ["dubai", "uae", "abu dhabi", "sharjah"])) {
      return "🇦🇪";
    }
    if (_matchesDestination(destination, ["singapore"])) return "🇸🇬";
    if (_matchesDestination(destination, ["barcelona", "spain", "madrid", "seville", "valencia"])) {
      return "🇪🇸";
    }
    if (_matchesDestination(destination, ["berlin", "germany", "munich", "frankfurt", "hamburg"])) {
      return "🇩🇪";
    }
    if (_matchesDestination(destination, ["amsterdam", "netherlands", "holland"])) {
      return "🇳🇱";
    }
    if (_matchesDestination(destination, ["bali", "indonesia", "jakarta", "lombok"])) return "🇮🇩";
    if (_matchesDestination(destination, ["cairo", "egypt", "alexandria", "giza"])) return "🇪🇬";
    if (_matchesDestination(destination, ["toronto", "canada", "vancouver", "banff", "montreal"])) {
      return "🇨🇦";
    }
    if (_matchesDestination(destination, ["rio", "brazil", "sao paulo"])) return "🇧🇷";
    if (_matchesDestination(destination, ["seoul", "korea", "south korea", "busan"])) return "🇰🇷";
    if (_matchesDestination(destination, ["cape town", "south africa", "johannesburg"])) {
      return "🇿🇦";
    }
    if (_matchesDestination(destination, ["switzerland", "zurich", "geneva", "lucerne", "alps"])) return "🇨🇭";
    if (_matchesDestination(destination, ["greece", "athens", "santorini", "mykonos", "crete"])) {
      return "🇬🇷";
    }
    if (_matchesDestination(destination, ["norway", "oslo", "bergen", "fjord"])) return "🇳🇴";
    if (_matchesDestination(destination, ["iceland", "reykjavik"])) return "🇮🇸";
    return "🌍";
  }

  static String getTripImage(String destination) {
    if (_matchesDestination(destination, ["thailand", "phuket", "bangkok", "chiang mai", "pattaya", "krabi", "koh samui"])) {
      return "https://images.unsplash.com/photo-1589394815804-964ed0be2eb5?w=800";
    }
    if (_matchesDestination(destination, ["muscat", "oman", "salalah", "nizwa"])) {
      return "https://images.unsplash.com/photo-1578895101407-f831968ebdc2?w=800";
    }
    if (_matchesDestination(destination, ["tokyo", "japan", "kyoto", "osaka", "fukuoka"])) {
      return "https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?w=800";
    }
    if (_matchesDestination(destination, ["paris", "france", "nice", "lyon"])) {
      return "https://images.unsplash.com/photo-1502602898657-3e91760cbb34?w=800";
    }
    if (_matchesDestination(destination, ["london", "uk", "england", "united kingdom"])) {
      return "https://images.unsplash.com/photo-1513635269975-59663e0ac1ad?w=800";
    }
    if (_matchesDestination(destination, ["rome", "italy", "florence", "venice", "milan"])) {
      return "https://images.unsplash.com/photo-1552832230-c0197dd311b5?w=800";
    }
    if (_matchesDestination(destination, ["new york", "nyc", "manhattan", "usa", "us"])) {
      return "https://images.unsplash.com/photo-1496442226666-8d4d0e62e6e9?w=800";
    }
    if (_matchesDestination(destination, ["san francisco", "california", "los angeles"])) {
      return "https://images.unsplash.com/photo-1501594907352-04cda38ebc29?w=800";
    }
    if (_matchesDestination(destination, ["sydney", "australia", "melbourne"])) {
      return "https://images.unsplash.com/photo-1506973035872-a4ec16b8e8d9?w=800";
    }
    if (_matchesDestination(destination, ["delhi", "india", "mumbai", "jaipur", "goa", "agra", "munnar", "kerala"])) {
      return "https://images.unsplash.com/photo-1524492412937-b28074a5d7da?w=800";
    }
    if (_matchesDestination(destination, ["dubai", "uae", "abu dhabi"])) {
      return "https://images.unsplash.com/photo-1512453979798-5ea266f8880c?w=800";
    }
    if (_matchesDestination(destination, ["singapore"])) {
      return "https://images.unsplash.com/photo-1525625293386-3f8f99389edd?w=800";
    }
    if (_matchesDestination(destination, ["barcelona", "spain", "madrid"])) {
      return "https://images.unsplash.com/photo-1583422409516-2895a77efded?w=800";
    }
    if (_matchesDestination(destination, ["berlin", "germany", "munich"])) {
      return "https://images.unsplash.com/photo-1560969184-10fe8719e047?w=800";
    }
    if (_matchesDestination(destination, ["amsterdam", "netherlands"])) {
      return "https://images.unsplash.com/photo-1512470876302-972faa2aa9a4?w=800";
    }
    if (_matchesDestination(destination, ["bali", "indonesia"])) {
      return "https://images.unsplash.com/photo-1537996194471-e657df975ab4?w=800";
    }
    if (_matchesDestination(destination, ["cairo", "egypt"])) {
      return "https://images.unsplash.com/photo-1572252009286-268acec5ca0a?w=800";
    }
    if (_matchesDestination(destination, ["switzerland", "zurich", "alps", "geneva", "lucerne"])) {
      return "https://images.unsplash.com/photo-1530122037265-a5f1f91d3b99?w=800";
    }
    if (_matchesDestination(destination, ["greece", "santorini", "athens", "mykonos", "crete"])) {
      return "https://images.unsplash.com/photo-1570077188670-e3a8d69ac5ff?w=800";
    }
    if (_matchesDestination(destination, ["norway", "oslo", "fjord", "bergen"])) {
      return "https://images.unsplash.com/photo-1516483638261-f4dbaf036963?w=800";
    }
    if (_matchesDestination(destination, ["iceland", "reykjavik"])) {
      return "https://images.unsplash.com/photo-1504893524553-b855bce32c67?w=800";
    }
    if (_matchesDestination(destination, ["canada", "toronto", "vancouver", "banff", "montreal"])) {
      return "https://images.unsplash.com/photo-1503614472-8c93d56e92ce?w=800";
    }
    if (_matchesDestination(destination, ["brazil", "rio", "sao paulo"])) {
      return "https://images.unsplash.com/photo-1483729558449-99ef09a8c325?w=800";
    }
    if (_matchesDestination(destination, ["seoul", "korea", "south korea", "busan"])) {
      return "https://images.unsplash.com/photo-1538485399081-7191377e8241?w=800";
    }
    if (_matchesDestination(destination, ["cape town", "south africa", "johannesburg"])) {
      return "https://images.unsplash.com/photo-1580618672591-eb180b1a973f?w=800";
    }
    return "https://images.unsplash.com/photo-1488646953014-85cb44e25828?w=800";
  }

  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}

String _parseId(dynamic jsonVal) {
  if (jsonVal == null) return "";
  if (jsonVal is String) return jsonVal;
  if (jsonVal is Map<String, dynamic>) {
    return (jsonVal["\$oid"] ??
            jsonVal["oid"] ??
            jsonVal["id"] ??
            jsonVal["_id"] ??
            "")
        .toString();
  }
  return jsonVal.toString();
}
