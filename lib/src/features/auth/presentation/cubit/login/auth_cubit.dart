import 'package:bloc/bloc.dart';
import 'package:wonder_souls/src/features/auth/presentation/cubit/login/auth_state.dart';

import '../../../domain/usecase/login_usecase.dart';
import '../../../domain/usecase/logout_usecase.dart';

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
      (_) => emit(Authenticated()),
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
