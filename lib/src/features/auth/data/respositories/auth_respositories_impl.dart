import 'package:fpdart/fpdart.dart';
import 'package:wonder_souls/src/config/model/failure.dart';
import 'package:wonder_souls/src/features/auth/data/datasource/auth_remote_data_source.dart';
import 'package:wonder_souls/src/features/auth/domain/repositories/auth_repositories.dart';

import '../../../../config/model/success.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  // final  AuthLocalDataSource authLocalDataSource;
  AuthRepositoryImpl(
    this.remoteDataSource,

    // this.authLocalDataSource,
  );

  @override
  Future<Either<Failure, String>> login({
    required String email,
    required String password,
  }) async {
    try {
      final result = await remoteDataSource.login(
        email: email,
        password: password,
      );
      // authLocalDataSource.saveUser(authLocalDataSource.getUser()?.copyWith(email: email));
      
      if(result is Failure<String>){
       return  Left(result);
      }

         final token = (result as Success<String>).data;

      return Right(token);


    } catch (e) {
      return Left(Failure(message: "Login failed"));
    }
  }

  @override
  Future<bool> isLoggedIn() {
    return remoteDataSource.isLoggedIn();
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await remoteDataSource.logout();
      // authLocalDataSource.saveUser(authLocalDataSource.getUser()?.copyWith(email: email));
      return Right(null);
    } catch (e) {
      return Left(Failure(message: "Login failed"));
    }
  }
}
