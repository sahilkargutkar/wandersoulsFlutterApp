class UserPreferencesModel {
  final String? theme;
  final String? language;
  final bool? notificationsEnabled;

  const UserPreferencesModel({
    this.theme,
    this.language,
    this.notificationsEnabled,
  });

  factory UserPreferencesModel.fromJson(Map<String, dynamic> json) {
    return UserPreferencesModel(
      theme: json['theme'] as String?,
      language: json['language'] as String?,
      notificationsEnabled: json['notificationsEnabled'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'theme': theme,
      'language': language,
      'notificationsEnabled': notificationsEnabled,
    };
  }

  UserPreferencesModel copyWith({
    String? theme,
    String? language,
    bool? notificationsEnabled,
  }) {
    return UserPreferencesModel(
      theme: theme ?? this.theme,
      language: language ?? this.language,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}
