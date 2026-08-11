class TravelPreferenceModel {
  final String? id;
  final String? userId;
  final String? travelStyle;
  final List<String> preferredCategories;
  final String? budgetPreference;
  final String? accommodationPreference;
  final List<String> dietaryRestrictions;

  TravelPreferenceModel({
    this.id,
    this.userId,
    this.travelStyle,
    this.preferredCategories = const [],
    this.budgetPreference,
    this.accommodationPreference,
    this.dietaryRestrictions = const [],
  });

  factory TravelPreferenceModel.fromJson(Map<String, dynamic> json) {
    return TravelPreferenceModel(
      id: json['id'],
      userId: json['userId'],
      travelStyle: json['travelStyle'],
      preferredCategories: json['preferredCategories'] != null
          ? List<String>.from(json['preferredCategories'])
          : [],
      budgetPreference: json['budgetPreference'],
      accommodationPreference: json['accommodationPreference'],
      dietaryRestrictions: json['dietaryRestrictions'] != null
          ? List<String>.from(json['dietaryRestrictions'])
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) "id": id,
      if (userId != null) "userId": userId,
      "travelStyle": travelStyle ?? "Explorer",
      "preferredCategories": preferredCategories,
      "budgetPreference": budgetPreference ?? "Moderate",
      "accommodationPreference": accommodationPreference ?? "Hotel",
      "dietaryRestrictions": dietaryRestrictions,
    };
  }
}
