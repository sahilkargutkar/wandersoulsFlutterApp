import 'package:wonder_souls/src/features/auth/domain/enitiy/collaborator.dart';

class CollaboratorModel extends CollaboratorEntity {
  const CollaboratorModel({
    required super.userId,
    required super.userName,
    required super.userEmail,
    required super.permissionLevel,
    required super.addedAt,
  });

  factory CollaboratorModel.fromJson(Map<String, dynamic> json) {
    return CollaboratorModel(
      userId: json['userId']?['timestamp'] != null
          ? json['userId']['timestamp'].toString()
          : json['userId']?.toString() ?? '',
      userName: json['userName'] ?? '',
      userEmail: json['userEmail'] ?? '',
      permissionLevel: json['permissionLevel'] ?? '',
      addedAt: json['addedAt'] != null
          ? DateTime.parse(json['addedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "userId": userId,
      "userName": userName,
      "userEmail": userEmail,
      "permissionLevel": permissionLevel,
      "addedAt": addedAt.toIso8601String(),
    };
  }
}
