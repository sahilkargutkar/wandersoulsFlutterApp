import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wonder_souls/src/features/auth/domain/repositories/auth_repositories.dart';
import 'package:wonder_souls/src/features/auth/data/model1/register_request.dart';
import 'package:uuid/uuid.dart';

abstract class SignUpState {}

class SignUpInitial extends SignUpState {}

class SignUpLoading extends SignUpState {}

class SignUpSuccess extends SignUpState {}

class SignUpFailure extends SignUpState {
  final String message;
  SignUpFailure(this.message);
}

class SignUpCubit extends Cubit<SignUpState> {
  final AuthRepository repository;

  SignUpCubit(this.repository) : super(SignUpInitial());

  Future<void> registerUser({
    required String name,
    required String email,
    required String password,
    required String country,
    required String phone,
    required List<String> preferences,
    required String currency,
    required String language,
    String? profilePicturePath,
  }) async {
    emit(SignUpLoading());

    final now = DateTime.now().toUtc().toIso8601String();
    final request = RegisterRequest(
      id: const Uuid().v4(),
      userName: name.replaceAll(' ', '').toLowerCase(),
      email: email,
      phoneNumber: phone,
      passwordHash: password,
      name: name,
      profilePicture: profilePicturePath ?? '',
      defaultCurrency: currency,
      preferences: {
        'language': language,
        'country': country,
        'travelTastes': preferences,
        'theme': 'light',
      },
      createdBy: 'System',
      createdAt: now,
      isActive: true,
      modifiedBy: 'System',
      modifiedOn: now,
    );

    final result = await repository.register(request);

    result.fold(
      (failure) => emit(SignUpFailure(failure.message)),
      (_) => emit(SignUpSuccess()),
    );
  }
}
