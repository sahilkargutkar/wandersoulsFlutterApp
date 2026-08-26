class UserPreferencesModel {
  final String? theme;
  final String? language;
  final String? country;
  final bool? notificationsEnabled;
  final List<String>? travelTastes;

  const UserPreferencesModel({
    this.theme,
    this.language,
    this.country,
    this.notificationsEnabled,
    this.travelTastes,
  });

  factory UserPreferencesModel.fromJson(Map<String, dynamic> json) {
    return UserPreferencesModel(
      theme: json['theme'] as String?,
      language: json['language'] as String?,
      country: json['country'] as String?,
      notificationsEnabled: json['notificationsEnabled'] as bool?,
      travelTastes: json['travelTastes'] != null
          ? List<String>.from(json['travelTastes'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'theme': theme,
      'language': language,
      'country': country,
      'notificationsEnabled': notificationsEnabled,
      if (travelTastes != null) 'travelTastes': travelTastes,
    };
  }

  UserPreferencesModel copyWith({
    String? theme,
    String? language,
    String? country,
    bool? notificationsEnabled,
    List<String>? travelTastes,
  }) {
    return UserPreferencesModel(
      theme: theme ?? this.theme,
      language: language ?? this.language,
      country: country ?? this.country,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      travelTastes: travelTastes ?? this.travelTastes,
    );
  }
}
