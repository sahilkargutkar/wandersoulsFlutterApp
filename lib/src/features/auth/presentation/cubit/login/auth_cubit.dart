import 'package:bloc/bloc.dart';
import 'package:wonder_souls/src/features/auth/presentation/cubit/login/auth_state.dart';

import '../../../domain/usecase/login_usecase.dart';
import '../../../domain/usecase/logout_usecase.dart';

import 'package:wonder_souls/src/config/core/injector/injector.dart';
import 'package:wonder_souls/src/features/notifications/data/services/fcm_notification_service.dart';

class AuthCubit extends Cubit<AuthState> {
  final LoginUseCase loginUseCase;
  final LogoutUseCase logoutUseCase;

  AuthCubit({required this.loginUseCase, required this.logoutUseCase})
    : super(AuthInitial());

  Future<void> login(String email, String password) async {
    emit(AuthLoading());

    final result = await loginUseCase(
      LoginParams(email: email, password: password),
    );

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) {
        if (sl.isRegistered<FcmNotificationService>()) {
          sl<FcmNotificationService>().registerDeviceAfterLogin();
        }
        emit(Authenticated());
      },
    );
  }

  Future<void> logout() async {
    emit(AuthLoading());
    final result = await logoutUseCase();

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(Unauthenticated()),
    );
  }
}
