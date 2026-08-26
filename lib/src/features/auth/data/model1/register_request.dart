class RegisterRequest {
  final String id;
  final String userName;
  final String email;
  final String phoneNumber;
  final String password;
  final String name;
  final String profilePicture;
  final String defaultCurrency;
  final Map<String, dynamic> preferences;
  final String createdBy;
  final String createdAt;
  final bool isActive;
  final String modifiedBy;
  final String modifiedOn;

  RegisterRequest({
    required this.id,
    required this.userName,
    required this.email,
    required this.phoneNumber,
    required this.password,
    required this.name,
    required this.profilePicture,
    required this.defaultCurrency,
    required this.preferences,
    required this.createdBy,
    required this.createdAt,
    required this.isActive,
    required this.modifiedBy,
    required this.modifiedOn,
  });

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "userName": userName,
      "username": userName,
      "email": email,
      "phoneNumber": phoneNumber,
      "password": password,
      "passwordHash": password,
      "name": name,
      "profilePicture": profilePicture,
      "defaultCurrency": defaultCurrency,
      "preferences": preferences,
      "createdBy": createdBy,
      "createdAt": createdAt,
      "isActive": isActive,
      "modifiedBy": modifiedBy,
      "modifiedOn": modifiedOn,
    };
  }
}
