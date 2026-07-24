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
