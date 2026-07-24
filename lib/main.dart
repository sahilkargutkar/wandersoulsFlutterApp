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
import 'package:wonder_souls/src/features/auth/presentation/screens/splash_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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
          ],
          child: MaterialApp(
            navigatorKey: navigatorKey,
            debugShowCheckedModeBanner: false,
            // home: LoginScreen(),
            initialRoute: SplashScreen.routeName,
            onGenerateRoute: generateRoute,
            theme: AppTheme.light, // ✅ Use your custom light theme
            darkTheme: AppTheme.dark, // ✅ Optional: support dark mode
            themeMode: ThemeMode.system, // Use system dark/light
          ),
        );
      },
    );
  }
}
