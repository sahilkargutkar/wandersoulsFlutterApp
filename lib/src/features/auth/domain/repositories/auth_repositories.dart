import 'package:fpdart/fpdart.dart';
import 'package:wonder_souls/src/config/model/failure.dart';

abstract class AuthRepository {
  Future<Either<Failure, String>> login({
    required String email,
    required String password,
  });
  Future<bool> isLoggedIn();

  Future<Either<Failure, void>> logout();
}
