import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wonder_souls/src/config/core/injector/injector.dart';
import 'package:wonder_souls/src/config/route/app_routes.dart';
import 'package:wonder_souls/src/config/theme/app_theme.dart';
import 'package:wonder_souls/src/features/auth/presentation/cubit/isLoginCubit/is_login_cubit.dart';
import 'package:wonder_souls/src/features/auth/presentation/cubit/login/auth_cubit.dart';
import 'package:wonder_souls/src/config/theme/theme_cubit.dart';
import 'package:wonder_souls/src/features/trips/presentation/cubit/saved_places_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await setupLocator();

  /// System UI
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarColor: Colors.transparent,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 640),
      builder: (context, child) {
        return MultiBlocProvider(
          providers: [
            BlocProvider<IsLoginCubit>(
              create: (_) => sl<IsLoginCubit>()..checkAuth(),
            ),
            BlocProvider<AuthCubit>(create: (_) => sl<AuthCubit>()),
            BlocProvider<ThemeCubit>(create: (_) => sl<ThemeCubit>()),
            BlocProvider<SavedPlacesCubit>(create: (_) => sl<SavedPlacesCubit>()),
          ],
          child: BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (context, themeMode) {
              return MaterialApp.router(
                debugShowCheckedModeBanner: false,
                routerConfig: router,
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
