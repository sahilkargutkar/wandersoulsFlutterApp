import 'package:bloc/bloc.dart';

import '../../../domain/usecase/is_logged_in_usecase.dart';
import 'is_login_state.dart';

class IsLoginCubit extends Cubit<IsLoginState> {
  final IsLoggedInUseCase isLoggedInUseCase;

  IsLoginCubit(this.isLoggedInUseCase) : super(IsLoginInitial());

  Future<void> checkAuth() async {
    emit(IsLoginLoading());

    final loggedIn = await isLoggedInUseCase();
    if (loggedIn) {
      emit(IsLoggedIn());
    } else {
      emit(IsLoggedOut());
    }
  }
}
