class PlaceModel {
  final String name;
  final String placeId;

  final String description;
  final String address;

  final double? rating;
  final int? userRatingsTotal;

  final double? latitude;
  final double? longitude;

  final String? googleMapsUrl;

  final List<String> types;

  PlaceModel({
    required this.name,
    required this.placeId,
    required this.description,
    required this.address,
    this.rating,
    this.userRatingsTotal,
    this.latitude,
    this.longitude,
    this.googleMapsUrl,
    required this.types,
  });

  factory PlaceModel.fromJson(Map<String, dynamic> json) {
    return PlaceModel(
      /// NAME
      name: json['name'] ?? json['structured_formatting']?['main_text'] ?? '',

      /// PLACE ID
      placeId: json['place_id'] ?? '',

      /// DESCRIPTION
      description: json['description'] ?? json['address'] ?? '',

      /// ADDRESS
      address: json['address'] ?? json['description'] ?? '',

      /// RATING
      rating: (json['rating'] as num?)?.toDouble(),

      /// TOTAL RATINGS
      userRatingsTotal: json['user_ratings_total'] as int?,

      /// LATITUDE
      latitude: (json['location']?['lat'] as num?)?.toDouble(),

      /// LONGITUDE
      longitude: (json['location']?['lng'] as num?)?.toDouble(),

      /// GOOGLE MAP URL
      googleMapsUrl: json['google_maps_url'] as String?,

      /// TYPES
      types: json['types'] != null ? List<String>.from(json['types']) : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "place_id": placeId,
      "description": description,
      "address": address,
      "rating": rating,
      "user_ratings_total": userRatingsTotal,

      "location": {"lat": latitude, "lng": longitude},

      "google_maps_url": googleMapsUrl,

      "types": types,
    };
  }
}
