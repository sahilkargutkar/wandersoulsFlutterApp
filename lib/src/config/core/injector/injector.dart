import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wonder_souls/src/config/core/local_storage/token_storage.dart';
import 'package:wonder_souls/src/config/core/services/api_services.dart';
import 'package:wonder_souls/src/config/core/services/google_map_services.dart';
import 'package:wonder_souls/src/config/utils/api_constant.dart';
import 'package:wonder_souls/src/features/auth/data/datasource/auth_local_data_source.dart';
import 'package:wonder_souls/src/features/auth/data/datasource/auth_remote_data_source.dart';
import 'package:wonder_souls/src/features/auth/data/respositories/auth_respositories_impl.dart';
import 'package:wonder_souls/src/features/auth/domain/repositories/auth_repositories.dart';
import 'package:wonder_souls/src/features/auth/domain/usecase/is_logged_in_usecase.dart';
import 'package:wonder_souls/src/features/auth/domain/usecase/login_usecase.dart';
import 'package:wonder_souls/src/features/auth/domain/usecase/logout_usecase.dart';
import 'package:wonder_souls/src/features/auth/presentation/cubit/isLoginCubit/is_login_cubit.dart';
import 'package:wonder_souls/src/features/auth/presentation/cubit/login/auth_cubit.dart';
import 'package:wonder_souls/src/features/auth/presentation/cubit/password/password_cubit.dart';
import 'package:wonder_souls/src/config/theme/theme_cubit.dart';
import 'package:wonder_souls/src/features/auth/presentation/cubit/signup/signup_cubit.dart';
import 'package:wonder_souls/src/features/trips/presentation/cubit/saved_places_cubit.dart';
import 'package:wonder_souls/src/features/trips/presentation/cubit/blogs_cubit.dart';

final sl = GetIt.instance;

Future<void> setupLocator() async {
  /// Secure Storage (external package)
  sl.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );

  /// CORE SERVICES
  sl.registerLazySingleton<TokenStorage>(() => TokenStorage(sl()));

  sl.registerLazySingleton<ApiService>(
    () => ApiService(sl(), baseURL: ApiConstants.baseUrl),
  );
  sl.registerLazySingleton<GoogleMapsApiService>(
    () => GoogleMapsApiService(
      apiKey: ApiConstants.googleMapApiKey,
      baseURL: ApiConstants.mapURL,
    ),
  );

  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);
  initAuth();
}

Future<void> initAuth() async {
  /// ---------------- DATA SOURCE ----------------
  ///
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(sl()),
  );

  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(
      apiService: sl(),
      tokenStorage: sl(),
      localDataSource: sl(),
    ),
  );

  /// ---------------- REPOSITORY ----------------
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));

  /// ---------------- USECASE ----------------
  sl.registerLazySingleton(() => LoginUseCase(sl()));

  sl.registerLazySingleton(() => IsLoggedInUseCase(sl()));

  sl.registerLazySingleton(() => LogoutUseCase(sl()));

  /// ---------------- Cubit ----------------

  sl.registerFactory<AuthCubit>(
    () => AuthCubit(loginUseCase: sl(), logoutUseCase: sl()),
  );
  sl.registerFactory<IsLoginCubit>(() => IsLoginCubit(sl()));

  sl.registerFactory<PasswordCubit>(() => PasswordCubit());

  sl.registerFactory<SignUpCubit>(() => SignUpCubit(sl()));

  sl.registerFactory<ThemeCubit>(() => ThemeCubit(sl()));

  sl.registerFactory<SavedPlacesCubit>(() => SavedPlacesCubit(sl()));
  sl.registerFactory<BlogsCubit>(() => BlogsCubit());
}
