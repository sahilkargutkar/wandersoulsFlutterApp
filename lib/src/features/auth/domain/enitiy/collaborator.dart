import 'package:equatable/equatable.dart';

class CollaboratorEntity extends Equatable {
  final String userId;
  final String userName;
  final String userEmail;
  final String permissionLevel;
  final DateTime addedAt;

  const CollaboratorEntity({
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.permissionLevel,
    required this.addedAt,
  });

  @override
  List<Object?> get props => [
    userId,
    userName,
    userEmail,
    permissionLevel,
    addedAt,
  ];
}
