class CountryHelper {
  CountryHelper._();

  /// Map of city/region/destination keywords to 2-letter ISO country codes
  static final Map<String, String> _cityToCountryCode = {
    // India
    'shillong': 'in',
    'meghalaya': 'in',
    'delhi': 'in',
    'new delhi': 'in',
    'mumbai': 'in',
    'bangalore': 'in',
    'bengaluru': 'in',
    'goa': 'in',
    'jaipur': 'in',
    'munnar': 'in',
    'kerala': 'in',
    'agra': 'in',
    'kolkata': 'in',
    'chennai': 'in',
    'hyderabad': 'in',
    'pune': 'in',
    'varanasi': 'in',
    'ladakh': 'in',
    'manali': 'in',
    'shimla': 'in',
    'rishikesh': 'in',
    'darjeeling': 'in',
    'india': 'in',

    // Japan
    'tokyo': 'jp',
    'kyoto': 'jp',
    'osaka': 'jp',
    'fukuoka': 'jp',
    'sapporo': 'jp',
    'hiroshima': 'jp',
    'nara': 'jp',
    'japan': 'jp',

    // France
    'paris': 'fr',
    'nice': 'fr',
    'lyon': 'fr',
    'marseille': 'fr',
    'bordeaux': 'fr',
    'france': 'fr',

    // UK
    'london': 'gb',
    'edinburgh': 'gb',
    'manchester': 'gb',
    'liverpool': 'gb',
    'scotland': 'gb',
    'wales': 'gb',
    'uk': 'gb',
    'united kingdom': 'gb',
    'england': 'gb',

    // Italy
    'rome': 'it',
    'milan': 'it',
    'florence': 'it',
    'venice': 'it',
    'naples': 'it',
    'italy': 'it',

    // USA
    'new york': 'us',
    'los angeles': 'us',
    'san francisco': 'us',
    'miami': 'us',
    'chicago': 'us',
    'las vegas': 'us',
    'vegas': 'us',
    'california': 'us',
    'usa': 'us',
    'united states': 'us',
    'us': 'us',

    // Thailand
    'bangkok': 'th',
    'phuket': 'th',
    'chiang mai': 'th',
    'pattaya': 'th',
    'krabi': 'th',
    'koh samui': 'th',
    'thailand': 'th',

    // Singapore
    'singapore': 'sg',

    // UAE
    'dubai': 'ae',
    'abu dhabi': 'ae',
    'sharjah': 'ae',
    'uae': 'ae',
    'united arab emirates': 'ae',

    // Australia
    'sydney': 'au',
    'melbourne': 'au',
    'brisbane': 'au',
    'perth': 'au',
    'australia': 'au',

    // Canada
    'toronto': 'ca',
    'vancouver': 'ca',
    'montreal': 'ca',
    'canada': 'ca',

    // Indonesia
    'bali': 'id',
    'jakarta': 'id',
    'indonesia': 'id',

    // Malaysia
    'kuala lumpur': 'my',
    'penang': 'my',
    'malaysia': 'my',

    // Oman
    'muscat': 'om',
    'salalah': 'om',
    'nizwa': 'om',
    'oman': 'om',

    // Spain
    'barcelona': 'es',
    'madrid': 'es',
    'seville': 'es',
    'spain': 'es',

    // Germany
    'berlin': 'de',
    'munich': 'de',
    'frankfurt': 'de',
    'germany': 'de',

    // Switzerland
    'zurich': 'ch',
    'geneva': 'ch',
    'lucerne': 'ch',
    'interlaken': 'ch',
    'switzerland': 'ch',

    // Vietnam
    'hanoi': 'vn',
    'ho chi minh': 'vn',
    'da nang': 'vn',
    'vietnam': 'vn',

    // South Korea
    'seoul': 'kr',
    'busan': 'kr',
    'south korea': 'kr',
    'korea': 'kr',
  };

  /// Returns 2-letter ISO country code (e.g. 'in', 'us', 'jp') from destination string
  static String getCountryCode(String destination) {
    if (destination.trim().isEmpty) return '';

    // Check comma separation e.g. "Shillong, India" or "Tokyo, Japan"
    final parts = destination.split(',').map((p) => p.trim().toLowerCase()).toList();
    for (final part in parts.reversed) {
      if (_cityToCountryCode.containsKey(part)) {
        return _cityToCountryCode[part]!;
      }
    }

    // Check full string contains
    final lower = destination.toLowerCase();
    for (final entry in _cityToCountryCode.entries) {
      if (entry.key.length <= 3) {
        if (RegExp(r'\b' + RegExp.escape(entry.key) + r'\b').hasMatch(lower)) {
          return entry.value;
        }
      } else if (lower.contains(entry.key)) {
        return entry.value;
      }
    }

    return '';
  }

  /// Get country name from country code or destination
  static String getCountryName(String destination, [String? countryCode]) {
    final code = countryCode?.isNotEmpty == true
        ? countryCode!.toLowerCase()
        : getCountryCode(destination);

    switch (code) {
      case 'in':
        return 'India';
      case 'jp':
        return 'Japan';
      case 'fr':
        return 'France';
      case 'gb':
        return 'United Kingdom';
      case 'it':
        return 'Italy';
      case 'us':
        return 'United States';
      case 'th':
        return 'Thailand';
      case 'sg':
        return 'Singapore';
      case 'ae':
        return 'United Arab Emirates';
      case 'au':
        return 'Australia';
      case 'ca':
        return 'Canada';
      case 'id':
        return 'Indonesia';
      case 'my':
        return 'Malaysia';
      case 'om':
        return 'Oman';
      case 'es':
        return 'Spain';
      case 'de':
        return 'Germany';
      case 'ch':
        return 'Switzerland';
      case 'vn':
        return 'Vietnam';
      case 'kr':
        return 'South Korea';
      default:
        // Try extracting after comma
        if (destination.contains(',')) {
          return destination.split(',').last.trim();
        }
        return destination;
    }
  }

  /// Currency symbol for country
  static String getCurrencySymbol(String destination, [String? countryCode]) {
    final code = countryCode?.isNotEmpty == true
        ? countryCode!.toLowerCase()
        : getCountryCode(destination);

    switch (code) {
      case 'in':
        return '₹';
      case 'gb':
        return '£';
      case 'eu':
      case 'fr':
      case 'it':
      case 'es':
      case 'de':
        return '€';
      case 'jp':
        return '¥';
      case 'th':
        return '฿';
      case 'ae':
        return 'AED ';
      case 'om':
        return 'OMR ';
      case 'kr':
        return '₩';
      case 'us':
      case 'ca':
      case 'au':
      case 'sg':
        return '\$';
      default:
        return '₹';
    }
  }

  /// Check if destination is in India
  static bool isIndia(String destination) {
    return getCountryCode(destination) == 'in';
  }

  /// Curated places by destination/country as an immediate reliable fallback
  static List<Map<String, dynamic>> getCuratedPlaces(String destination) {
    final lower = destination.toLowerCase();
    final code = getCountryCode(destination);

    if (code == 'in' || lower.contains('shillong') || lower.contains('meghalaya')) {
      return [
        {
          "name": "Umiam Lake",
          "placeId": "umiam_lake_shillong",
          "category": "Nature & Parks",
          "rating": 4.6,
          "userRatingCount": 2100,
          "address": "Umiam, Ri Bhoi District, Shillong, Meghalaya",
          "priceText": "Free",
          "timeRange": "9:00 AM – 10:30 AM",
          "photoUrl":
              "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=600&q=80",
        },
        {
          "name": "Elephant Falls",
          "placeId": "elephant_falls_shillong",
          "category": "Waterfall",
          "rating": 4.4,
          "userRatingCount": 1800,
          "address": "Upper Shillong, Meghalaya",
          "priceText": "₹20 / person",
          "timeRange": "11:00 AM – 12:00 PM",
          "photoUrl":
              "https://images.unsplash.com/photo-1432405972618-c60b0225b8f9?auto=format&fit=crop&w=600&q=80",
        },
        {
          "name": "Shillong Peak",
          "placeId": "shillong_peak",
          "category": "Viewpoint & Scenic",
          "rating": 4.3,
          "userRatingCount": 1400,
          "address": "Laitkor Peak, Shillong, Meghalaya",
          "priceText": "₹50 / person",
          "timeRange": "1:00 PM – 2:30 PM",
          "photoUrl":
              "https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?auto=format&fit=crop&w=600&q=80",
        },
        {
          "name": "Ward's Lake",
          "placeId": "wards_lake_shillong",
          "category": "Lake & Garden",
          "rating": 4.2,
          "userRatingCount": 950,
          "address": "Police Bazar, Shillong, Meghalaya",
          "priceText": "₹30 / person",
          "timeRange": "2:00 PM – 3:00 PM",
          "photoUrl":
              "https://images.unsplash.com/photo-1519331379826-f10be5486c6f?auto=format&fit=crop&w=600&q=80",
        },
        {
          "name": "Don Bosco Museum",
          "placeId": "don_bosco_museum_shillong",
          "category": "Museum & Cultural",
          "rating": 4.7,
          "userRatingCount": 2800,
          "address": "Mawlai, Shillong, Meghalaya",
          "priceText": "₹100 / person",
          "timeRange": "10:00 AM – 12:30 PM",
          "photoUrl":
              "https://images.unsplash.com/photo-1565008447742-97f6f38c985c?auto=format&fit=crop&w=600&q=80",
        },
        {
          "name": "Laitlum Canyons",
          "placeId": "laitlum_canyons",
          "category": "Nature & Hiking",
          "rating": 4.8,
          "userRatingCount": 1900,
          "address": "East Khasi Hills, Meghalaya",
          "priceText": "Free",
          "timeRange": "3:00 PM – 5:30 PM",
          "photoUrl":
              "https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=600&q=80",
        },
      ];
    }

    if (code == 'jp') {
      return [
        {
          "name": "Senso-ji Temple",
          "placeId": "sensoji_tokyo",
          "category": "Historic & Cultural",
          "rating": 4.7,
          "userRatingCount": 45000,
          "address": "Asakusa, Taito City, Tokyo",
          "priceText": "Free",
          "timeRange": "9:00 AM – 11:00 AM",
          "photoUrl":
              "https://images.unsplash.com/photo-1503899036084-c55cdd92da26?auto=format&fit=crop&w=600&q=80",
        },
        {
          "name": "Meiji Jingu Shrine",
          "placeId": "meiji_jingu_tokyo",
          "category": "Shrine & Forest",
          "rating": 4.6,
          "userRatingCount": 32000,
          "address": "Yoyogikamizonocho, Shibuya City, Tokyo",
          "priceText": "Free",
          "timeRange": "1:00 PM – 3:00 PM",
          "photoUrl":
              "https://images.unsplash.com/photo-1542051841857-5f90071e7989?auto=format&fit=crop&w=600&q=80",
        },
      ];
    }

    return [];
  }
}
