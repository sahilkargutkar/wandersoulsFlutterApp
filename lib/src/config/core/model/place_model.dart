class PlaceModel {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;

  const PlaceModel({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });

  factory PlaceModel.fromJson(Map<String, dynamic> json) {
    final structured = json['structured_formatting'] as Map<String, dynamic>?;
    return PlaceModel(
      placeId: json['place_id'] ?? '',
      description: json['description'] ?? '',
      mainText: structured?['main_text'] ?? '',
      secondaryText: structured?['secondary_text'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'place_id': placeId,
    'description': description,
    'structured_formatting': {
      'main_text': mainText,
      'secondary_text': secondaryText,
    },
  };
}