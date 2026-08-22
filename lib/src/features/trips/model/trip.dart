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
  });

  factory TripData.fromJson(Map<String, dynamic> jsonMap) {
    final id = _parseId(jsonMap["id"]);
    final mainDest = jsonMap["mainDestination"] ?? "";
    final name =
        jsonMap["name"] ??
        (mainDest.isNotEmpty ? "Trip to $mainDest" : "My Trip");
    final description = jsonMap["description"] ?? "";
    final flag = _getCountryFlag(mainDest);

    DateTime? start;
    DateTime? end;
    if (jsonMap["startDate"] != null) {
      start = DateTime.tryParse(jsonMap["startDate"]);
    }
    if (jsonMap["endDate"] != null) {
      end = DateTime.tryParse(jsonMap["endDate"]);
    }

    final dateRange = _formatDateRange(start, end);
    final whoIsGoing = _capitalize(jsonMap["whoIsGoing"] ?? "solo");
    final budgetLevel = _capitalize(
      jsonMap["budget"]?["budgetType"] ?? "flexible",
    );
    final imageUrl = (jsonMap["imageUrl"] as String?)?.isNotEmpty == true
        ? jsonMap["imageUrl"]!
        : ((jsonMap["image"] as String?)?.isNotEmpty == true
            ? jsonMap["image"]!
            : _getTripImage(mainDest));

    List<String> travelTastes = [];
    if (jsonMap["travelTastes"] != null) {
      travelTastes = List<String>.from(jsonMap["travelTastes"]);
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

  static String _getCountryFlag(String destination) {
    final lower = destination.toLowerCase();
    if (lower.contains("tokyo") ||
        lower.contains("japan") ||
        lower.contains("osaka"))
      return "🇯🇵";
    if (lower.contains("paris") ||
        lower.contains("france") ||
        lower.contains("nice"))
      return "🇫🇷";
    if (lower.contains("london") ||
        lower.contains("uk") ||
        lower.contains("united kingdom"))
      return "🇬🇧";
    if (lower.contains("rome") ||
        lower.contains("italy") ||
        lower.contains("milan"))
      return "🇮🇹";
    if (lower.contains("new york") ||
        lower.contains("usa") ||
        lower.contains("united states"))
      return "🇺🇸";
    if (lower.contains("sydney") || lower.contains("australia")) return "🇦🇺";
    if (lower.contains("delhi") ||
        lower.contains("india") ||
        lower.contains("mumbai"))
      return "🇮🇳";
    return "🌍";
  }

  static String _getTripImage(String destination) {
    final lower = destination.toLowerCase();
    if (lower.contains("tokyo") || lower.contains("japan")) {
      return "https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?w=800";
    }
    if (lower.contains("paris") || lower.contains("france")) {
      return "https://images.unsplash.com/photo-1502602898657-3e91760cbb34?w=800";
    }
    if (lower.contains("london")) {
      return "https://images.unsplash.com/photo-1513635269975-59663e0ac1ad?w=800";
    }
    if (lower.contains("rome") || lower.contains("italy")) {
      return "https://images.unsplash.com/photo-1552832230-c0197dd311b5?w=800";
    }
    if (lower.contains("new york") || lower.contains("usa")) {
      return "https://images.unsplash.com/photo-1496442226666-8d4d0e62e6e9?w=800";
    }
    if (lower.contains("sydney") || lower.contains("australia")) {
      return "https://images.unsplash.com/photo-1506973035872-a4ec16b8e8d9?w=800";
    }
    if (lower.contains("india")) {
      return "https://images.unsplash.com/photo-1524492412937-b28074a5d7da?w=800";
    }
    return "https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?w=800";
  }

  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
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
