import 'package:wonder_souls/src/features/auth/domain/repositories/auth_repositories.dart';

class IsLoggedInUseCase {
  final AuthRepository repository;

  IsLoggedInUseCase(this.repository);

  Future<bool> call() {
    return repository.isLoggedIn();
  }
}
