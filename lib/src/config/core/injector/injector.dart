import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wonder_souls/src/config/core/local_storage/token_storage.dart';
import 'package:wonder_souls/src/config/core/services/api_services.dart';
import 'package:wonder_souls/src/config/core/services/google_map_services.dart';
import 'package:wonder_souls/src/config/core/services/google_places_new_service.dart';
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
import 'package:wonder_souls/src/features/trips/presentation/cubit/saved_articles_cubit.dart';
import 'package:wonder_souls/src/features/trips/presentation/cubit/blogs_cubit.dart';
import 'package:wonder_souls/src/features/notifications/data/datasources/notifications_remote_data_source.dart';
import 'package:wonder_souls/src/features/notifications/data/repositories/notifications_repository_impl.dart';
import 'package:wonder_souls/src/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:wonder_souls/src/features/notifications/domain/usecase/get_my_notifications_usecase.dart';
import 'package:wonder_souls/src/features/notifications/domain/usecase/mark_notification_read_usecase.dart';
import 'package:wonder_souls/src/features/notifications/domain/usecase/register_device_usecase.dart';
import 'package:wonder_souls/src/features/notifications/domain/usecase/unregister_device_usecase.dart';
import 'package:wonder_souls/src/features/notifications/data/services/device_registration_service.dart';
import 'package:wonder_souls/src/features/notifications/data/services/fcm_notification_service.dart';
import 'package:wonder_souls/src/features/notifications/presentation/cubit/notifications_cubit.dart';

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
  sl.registerLazySingleton<GooglePlacesNewService>(
    () => GooglePlacesNewService(),
  );

  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);
  initAuth();
  initNotifications();
}

Future<void> initNotifications() async {
  /// ---------------- DATA SOURCE ----------------
  sl.registerLazySingleton<NotificationsRemoteDataSource>(
    () => NotificationsRemoteDataSourceImpl(apiService: sl()),
  );

  /// ---------------- REPOSITORY ----------------
  sl.registerLazySingleton<NotificationsRepository>(
    () => NotificationsRepositoryImpl(sl()),
  );

  /// ---------------- USECASES ----------------
  sl.registerLazySingleton(() => GetMyNotificationsUseCase(sl()));
  sl.registerLazySingleton(() => MarkNotificationReadUseCase(sl()));
  sl.registerLazySingleton(() => RegisterDeviceUseCase(sl()));
  sl.registerLazySingleton(() => UnregisterDeviceUseCase(sl()));

  /// ---------------- SERVICES ----------------
  sl.registerLazySingleton(
    () => DeviceRegistrationService(
      registerDeviceUseCase: sl(),
      unregisterDeviceUseCase: sl(),
      sharedPreferences: sl(),
    ),
  );
  sl.registerLazySingleton(
    () => FcmNotificationService(
      deviceRegistrationService: sl(),
    ),
  );

  /// ---------------- CUBIT ----------------
  sl.registerFactory<NotificationsCubit>(
    () => NotificationsCubit(
      getMyNotificationsUseCase: sl(),
      markNotificationReadUseCase: sl(),
    ),
  );
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
  sl.registerFactory<SavedArticlesCubit>(() => SavedArticlesCubit(sl()));
  sl.registerFactory<BlogsCubit>(() => BlogsCubit());
}
