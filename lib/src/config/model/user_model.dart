import 'user_perferce_model.dart';

class UserModel {
  final String? id;
  final String? userName;
  final String? email;
  final String? passwordHash;
  final String? name;
  final String? profilePicture;
  final String? defaultCurrency;
  final String? country;
  final String? phoneNumber;
  final UserPreferencesModel? preferences;
  final String? createdBy;
  final DateTime? createdAt;
  final bool? isActive;
  final String? modifiedBy;
  final DateTime? modifiedOn;

  const UserModel({
    this.id,
    this.userName,
    this.email,
    this.passwordHash,
    this.name,
    this.profilePicture,
    this.defaultCurrency,
    this.country,
    this.phoneNumber,
    this.preferences,
    this.createdBy,
    this.createdAt,
    this.isActive,
    this.modifiedBy,
    this.modifiedOn,
  });

  /// FROM JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] ?? json['userId'] ?? json['Id'] ?? json['UserId']) as String?,
      userName: (json['userName'] ??
          json['username'] ??
          json['UserName'] ??
          json['Username'] ??
          json['user_name']) as String?,
      email: (json['email'] ?? json['Email']) as String?,
      passwordHash: (json['passwordHash'] ??
          json['PasswordHash'] ??
          json['password_hash']) as String?,
      name: (json['name'] ??
          json['Name'] ??
          json['fullName'] ??
          json['FullName'] ??
          json['full_name']) as String?,
      profilePicture: (json['profilePicture'] ??
          json['ProfilePicture'] ??
          json['profile_picture'] ??
          json['avatar'] ??
          json['avatarUrl']) as String?,
      defaultCurrency: (json['defaultCurrency'] ??
          json['DefaultCurrency'] ??
          json['currency'] ??
          json['Currency']) as String?,
      country: (json['country'] ??
          json['Country'] ??
          (json['preferences'] is Map<String, dynamic>
              ? (json['preferences']['country'] ??
                  json['preferences']['Country']) as String?
              : null)) as String?,
      phoneNumber: (json['phoneNumber'] ??
          json['PhoneNumber'] ??
          json['phone_number'] ??
          json['phone']) as String?,
      preferences: json['preferences'] != null || json['Preferences'] != null
          ? UserPreferencesModel.fromJson(
              (json['preferences'] ?? json['Preferences']) is Map<String, dynamic>
                  ? (json['preferences'] ?? json['Preferences'])
                  : {},
            )
          : null,
      createdBy: (json['createdBy'] ?? json['CreatedBy']) as String?,
      createdAt: (json['createdAt'] ?? json['CreatedAt']) != null
          ? DateTime.tryParse(json['createdAt'] ?? json['CreatedAt'])
          : null,
      isActive: (json['isActive'] ?? json['IsActive']) as bool?,
      modifiedBy: (json['modifiedBy'] ?? json['ModifiedBy']) as String?,
      modifiedOn: (json['modifiedOn'] ?? json['ModifiedOn']) != null
          ? DateTime.tryParse(json['modifiedOn'] ?? json['ModifiedOn'])
          : null,
    );
  }

  /// TO JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userName': userName,
      'email': email,
      'passwordHash': passwordHash,
      'name': name,
      'profilePicture': profilePicture,
      'defaultCurrency': defaultCurrency,
      if (country != null) 'country': country,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      'preferences': preferences?.toJson(),
      'createdBy': createdBy,
      'createdAt': createdAt?.toIso8601String(),
      'isActive': isActive,
      'modifiedBy': modifiedBy,
      'modifiedOn': modifiedOn?.toIso8601String(),
    };
  }

  /// COPY WITH
  UserModel copyWith({
    String? id,
    String? userName,
    String? email,
    String? passwordHash,
    String? name,
    String? profilePicture,
    String? defaultCurrency,
    String? country,
    String? phoneNumber,
    UserPreferencesModel? preferences,
    String? createdBy,
    DateTime? createdAt,
    bool? isActive,
    String? modifiedBy,
    DateTime? modifiedOn,
  }) {
    return UserModel(
      id: id ?? this.id,
      userName: userName ?? this.userName,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      name: name ?? this.name,
      profilePicture: profilePicture ?? this.profilePicture,
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
      country: country ?? this.country,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      preferences: preferences ?? this.preferences,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      modifiedBy: modifiedBy ?? this.modifiedBy,
      modifiedOn: modifiedOn ?? this.modifiedOn,
    );
  }
}
