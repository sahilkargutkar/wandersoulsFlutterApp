import 'package:equatable/equatable.dart';

sealed class IsLoginState extends Equatable {
  const IsLoginState();

  @override
  List<Object> get props => [];
}

final class IsLoginInitial extends IsLoginState {}

final class IsLoginLoading extends IsLoginState {}

final class IsLoggedIn extends IsLoginState {}

final class IsLoggedOut extends IsLoginState {}
