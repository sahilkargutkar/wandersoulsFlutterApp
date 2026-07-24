import 'package:fpdart/fpdart.dart';
import 'package:wonder_souls/src/config/model/failure.dart';

import '../repositories/auth_repositories.dart';

class LogoutUseCase {
  final AuthRepository repository;

  LogoutUseCase(this.repository);

  Future<Either<Failure, void>> call() async {
    return await repository.logout();
  }
}
