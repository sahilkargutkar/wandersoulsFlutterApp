import 'user_perferce_model.dart';

class UserModel {
  final String? id;
  final String? userName;
  final String? email;
  final String? passwordHash;
  final String? name;
  final String? profilePicture;
  final String? defaultCurrency;
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
      id: json['id'] as String?,
      userName: json['userName'] as String?,
      email: json['email'] as String?,
      passwordHash: json['passwordHash'] as String?,
      name: json['name'] as String?,
      profilePicture: json['profilePicture'] as String?,
      defaultCurrency: json['defaultCurrency'] as String?,
      preferences: json['preferences'] != null
          ? UserPreferencesModel.fromJson(json['preferences'])
          : null,
      createdBy: json['createdBy'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      isActive: json['isActive'] as bool?,
      modifiedBy: json['modifiedBy'] as String?,
      modifiedOn: json['modifiedOn'] != null
          ? DateTime.tryParse(json['modifiedOn'])
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
      preferences: preferences ?? this.preferences,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      modifiedBy: modifiedBy ?? this.modifiedBy,
      modifiedOn: modifiedOn ?? this.modifiedOn,
    );
  }
}
