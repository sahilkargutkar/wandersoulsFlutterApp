import 'package:wonder_souls/src/features/trips/model/trip.dart';

class StaticData {
  static List<Trip> getSavedTrips() {
    return [
      Trip(
        id: '1',
        name: 'Tokyo, Japan',
        location: 'Japan',
        country: 'Japan',
        imageUrl:
            'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?w=800',
        startDate: 'May 15, 2025',
        endDate: 'May 22, 2025',
        days: 7,
        places: [],
      ),
      Trip(
        id: '2',
        name: 'Prague, Prague',
        location: 'Czech Republic',
        country: 'Czech Republic',
        imageUrl:
            'https://images.unsplash.com/photo-1541849546-216549ae216d?w=800',
        startDate: 'June 10, 2025',
        endDate: 'June 17, 2025',
        days: 7,
        places: [],
      ),
    ];
  }

  static List<Trip> getMyTrips() {
    return [
      Trip(
        id: '3',
        name: 'Tokyo, Japan',
        location: 'Japan',
        country: 'Japan',
        imageUrl:
            'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?w=800',
        startDate: 'May 15, 2025',
        endDate: 'May 22, 2025',
        days: 7,
        places: getTokyoPlaces(),
      ),
      Trip(
        id: '4',
        name: 'Paris, France',
        location: 'France',
        country: 'France',
        imageUrl:
            'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?w=800',
        startDate: 'July 1, 2025',
        endDate: 'July 8, 2025',
        days: 7,
        places: [],
      ),
    ];
  }

  static List<Place> getTokyoPlaces() {
    return [
      Place(
        id: 'p1',
        name: 'Cafe de l\'ambre',
        imageUrl:
            'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=800',
        rating: 4.5,
        reviews: 1234,
        openTime: '08:00',
        closeTime: '09:00',
        price: 30.00,
        category: 'restaurant',
        activities: ['Cafe', '30 min', 'Order', 'Share'],
      ),
      Place(
        id: 'p2',
        name: 'Tokyo Tower',
        imageUrl:
            'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?w=800',
        rating: 4.8,
        reviews: 5432,
        openTime: '09:00',
        closeTime: '12:00',
        price: 50.00,
        category: 'attraction',
        activities: ['Tower', '1.5 hours', 'Order', 'Share'],
      ),
      Place(
        id: 'p3',
        name: 'Tsukiji Tomo Sushi',
        imageUrl:
            'https://images.unsplash.com/photo-1579584425555-c3ce17fd4351?w=800',
        rating: 4.9,
        reviews: 2156,
        openTime: '12:00',
        closeTime: '13:30',
        price: 38.00,
        category: 'restaurant',
        activities: ['Sushi', '45 min', 'Order', 'Share'],
      ),
      Place(
        id: 'p4',
        name: 'Imperial Palace',
        imageUrl:
            'https://images.unsplash.com/photo-1480796927426-f609979314bd?w=800',
        rating: 4.6,
        reviews: 3245,
        openTime: '15:30',
        closeTime: '18:00',
        price: 45.00,
        category: 'attraction',
        activities: ['Palace', '2 hours', 'Order', 'Share'],
      ),
      Place(
        id: 'p5',
        name: 'Sushi Iwa',
        imageUrl:
            'https://images.unsplash.com/photo-1583623025817-d180a2221d0a?w=800',
        rating: 4.7,
        reviews: 1876,
        openTime: '18:00',
        closeTime: '19:30',
        price: 60.00,
        category: 'restaurant',
        activities: ['Sushi', '1 hour', 'Order', 'Share'],
      ),
      Place(
        id: 'p6',
        name: 'Mandarin Oriental, Tokyo',
        imageUrl:
            'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800',
        rating: 4.9,
        reviews: 4532,
        openTime: '17:30',
        closeTime: '20:00',
        price: 350.00,
        category: 'hotel',
        activities: ['Hotel', '2.5 hours', 'Order', 'Share'],
      ),
    ];
  }
}

// ---------------- DATA ----------------

final List<Map<String, String>> destinations = [
  {
    'imageUrl':
        'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?w=400',
    'city': 'Tokyo, Tokyo',
    'country': 'Japan',
    'flagEmoji': '🇯🇵',
  },
  {
    'imageUrl':
        'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?w=400',
    'city': 'Paris, Paris',
    'country': 'France',
    'flagEmoji': '🇫🇷',
  },
  {
    'imageUrl':
        'https://images.unsplash.com/photo-1513635269975-59663e0ac1ad?w=400',
    'city': 'London, London',
    'country': 'United Kingdom',
    'flagEmoji': '🇬🇧',
  },
  {
    'imageUrl':
        'https://images.unsplash.com/photo-1523906834658-6e24ef2386f9?w=400',
    'city': 'New York, New York',
    'country': 'United States',
    'flagEmoji': '🇺🇸',
  },
];

final List<Map<String, String>> articles = [
  {
    'imageUrl':
        'https://images.unsplash.com/photo-1488646953014-85cb44e25828?w=400',
    'title': 'Hidden Gems: Uncovering Secret Destinations',
    'date': 'Dec 05, 2023',
  },
  {
    'imageUrl':
        'https://images.unsplash.com/photo-1436491865332-7a61a109cc05?w=400',
    'title': 'Packing Hacks: Travel Light, Travel Smart',
    'date': 'Dec 06, 2023',
  },
  {
    'imageUrl':
        'https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?w=400',
    'title': 'Budget Travel: Explore More, Spend Less',
    'date': 'Dec 07, 2023',
  },
  {
    'imageUrl':
        'https://images.unsplash.com/photo-1476514525535-07fb3b4ae5f1?w=400',
    'title': 'Best Photography Spots Around the World',
    'date': 'Dec 08, 2023',
  },
];
