import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:wonder_souls/src/config/core/injector/injector.dart';
import 'package:wonder_souls/src/config/core/services/api_services.dart';
import 'package:wonder_souls/src/config/route/app_routes.dart';
import 'package:wonder_souls/src/config/theme/app_theme.dart';
import 'package:wonder_souls/src/features/auth/presentation/cubit/isLoginCubit/is_login_cubit.dart';
import 'package:wonder_souls/src/features/auth/presentation/cubit/login/auth_cubit.dart';
import 'package:wonder_souls/src/config/theme/theme_cubit.dart';
import 'package:wonder_souls/src/features/trips/presentation/cubit/saved_places_cubit.dart';
import 'package:wonder_souls/src/features/trips/presentation/cubit/blogs_cubit.dart';
import 'package:wonder_souls/src/features/auth/presentation/screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await setupLocator();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarColor: Colors.transparent,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final GoRouter _router;
  late final IsLoginCubit _isLoginCubit;
  late final AuthCubit _authCubit;

  @override
  void initState() {
    super.initState();
    _isLoginCubit = sl<IsLoginCubit>()..checkAuth();
    _authCubit = sl<AuthCubit>();
    _router = buildRouter(isLoginCubit: _isLoginCubit, authCubit: _authCubit);

    final apiService = sl<ApiService>();
    apiService.onSessionExpired = () {
      _router.go(LoginScreen.routeName);
    };
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 640),
      builder: (context, child) {
        return MultiBlocProvider(
          providers: [
            BlocProvider<IsLoginCubit>.value(value: _isLoginCubit),
            BlocProvider<AuthCubit>.value(value: _authCubit),
            BlocProvider<ThemeCubit>(create: (_) => sl<ThemeCubit>()),
            BlocProvider<SavedPlacesCubit>(
              create: (_) => sl<SavedPlacesCubit>(),
            ),
            BlocProvider<BlogsCubit>(
              create: (_) => sl<BlogsCubit>()..fetchBlogs(),
            ),
          ],
          child: BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (context, themeMode) {
              return MaterialApp.router(
                debugShowCheckedModeBanner: false,
                routerConfig: _router,
                theme: AppTheme.light,
                darkTheme: AppTheme.dark,
                themeMode: themeMode,
              );
            },
          ),
        );
      },
    );
  }
}
