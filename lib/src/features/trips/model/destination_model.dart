class DestinationModel {
  final String? id;
  final String? tripId;
  final String? locationId;
  final String name;
  final String? imageUrl;
  final DateTime? visited;

  DestinationModel({
    this.id,
    this.tripId,
    this.locationId,
    required this.name,
    this.imageUrl,
    this.visited,
  });

  factory DestinationModel.fromJson(Map<String, dynamic> json) {
    return DestinationModel(
      id: json['id'],
      tripId: json['tripId'],
      locationId: json['locationId'],
      name: json['name'] ?? '',
      imageUrl: json['imageUrl'],
      visited: json['visited'] != null
          ? DateTime.tryParse(json['visited'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) "id": id,
      if (tripId != null) "tripId": tripId,
      if (locationId != null) "locationId": locationId,
      "name": name,
      "imageUrl": imageUrl ?? "",
      "visited": (visited ?? DateTime.now()).toUtc().toIso8601String(),
    };
  }
}
