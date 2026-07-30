import 'package:fpdart/fpdart.dart';
import 'package:wonder_souls/src/config/model/failure.dart';

import 'package:wonder_souls/src/features/auth/data/model1/register_request.dart';

abstract class AuthRepository {
  Future<Either<Failure, void>> register(RegisterRequest request);
  Future<Either<Failure, String>> login({
    required String email,
    required String password,
  });
  Future<bool> isLoggedIn();

  Future<Either<Failure, void>> logout();
}
