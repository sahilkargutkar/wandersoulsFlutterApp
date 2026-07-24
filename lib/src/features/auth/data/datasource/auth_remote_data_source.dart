import 'package:flutter/foundation.dart';
import 'package:wonder_souls/src/config/model/user_model.dart';
import 'package:wonder_souls/src/config/utils/api_constant.dart';
import 'package:wonder_souls/src/config/core/local_storage/token_storage.dart';
import 'package:wonder_souls/src/config/model/failure.dart';
import 'package:wonder_souls/src/features/auth/data/datasource/auth_local_data_source.dart';
import 'package:wonder_souls/src/features/auth/data/model1/login_response.dart';

import '../../../../config/core/services/api_services.dart';
import '../../../../config/model/api_result.dart';
import '../../../../config/model/success.dart';

/// AuthRemoteDataSource Responsibilities:
///
/// • Handles all authentication API calls
/// • Registers new users
/// • Logs in user and retrieves token + userId
/// • Fetches full user details after login
/// • Caches user data locally
/// • Checks if user is logged in (token exists)
/// • Clears token on logout
/// • Deletes user account

abstract interface class AuthRemoteDataSource {
  Future<ApiResult<void>> register({
    required String name,
    required String email,
    required String password,
  });

  Future<ApiResult<String>> login({
    required String email,
    required String password,
  });
  Future<bool> isLoggedIn();

  Future<void> logout();
  Future<ApiResult<void>> deleteAccount({required String userId});
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiService apiService;
  final TokenStorage tokenStorage;
  final AuthLocalDataSource localDataSource;

  AuthRemoteDataSourceImpl({
    required this.apiService,
    required this.tokenStorage,
    required this.localDataSource,
  });

  @override
  Future<ApiResult<void>> register({
    required String name,
    required String email,
    required String password,
  }) {
    return apiService.post<void>(
      ApiConstants.register,
      data: {"name": name, "email": email, "password": password},
      fromJson: (_) => null,
    );
  }

@override
  Future<ApiResult<String>> login({
    required String email,
    required String password,
  }) async {
    try {
      final loginResult = await apiService.post<LoginResponse>(
        ApiConstants.login,
        data: {"email": email, "password": password},
        fromJson: (json) => LoginResponse.fromJson(json["data"]),
      );

      switch (loginResult) {
        case Failure<LoginResponse>(message: final msg):
          return Failure(message: msg);

        case Success<LoginResponse>(data: final loginData):
          // Save token
          await tokenStorage.saveToken(loginData.token);

          // Fetch user
          final userResult = await apiService.get<UserModel>(
            ApiConstants.userById(loginData.userId),
            fromJson: (json) => UserModel.fromJson(json),
          );

          if (userResult is Success<UserModel>) {
            await localDataSource.saveUser(userResult.data);
          }

          return Success(loginData.token);
      default:   return Failure(message: "Something went wrong");
      }
    } catch (e) {
      return Failure(message: e.toString());
    }
  }

  @override
  Future<ApiResult<void>> deleteAccount({required String userId}) {
    return apiService.delete<void>(
      ApiConstants.userById(userId),
      fromJson: (_) => null,
    );
  }

  @override
  Future<bool> isLoggedIn() async {
    try {
      String token = await tokenStorage.getToken() ?? "";

      return token.isEmpty ? false : true;
    } on Exception catch (e) {
      return false;
    }
  }

  Failure<T> _handleError<T>(Exception e) {
    return Failure<T>(message: e.toString());
  }

  @override
  Future<void> logout() async {
    try {
      await tokenStorage.clearToken();
      await localDataSource.clearUser();
      return;
    } on Exception catch (e) {
      return;
    }
  }
}
