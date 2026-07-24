import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wonder_souls/src/config/core/assets/assets.dart';
import 'package:wonder_souls/src/config/theme/app_colors.dart';
import 'package:wonder_souls/src/features/auth/presentation/cubit/isLoginCubit/is_login_cubit.dart';
import 'package:wonder_souls/src/features/auth/presentation/screens/boarding_screens.dart';
import 'package:wonder_souls/src/features/home/presentation/screens/home_bottom_bar.dart';

import '../cubit/isLoginCubit/is_login_state.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const String routeName = "/";

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  Widget build(BuildContext context) {
    return BlocListener<IsLoginCubit, IsLoginState>(
      listener: (context, state) {
        if (state is IsLoggedIn) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            HomeBottomBar.routeName,
            (_) => false,
          );
        }

        if (state is IsLoggedOut) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            BoardingScreens.routeName,
            (_) => false,
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.lightPrimary, // green background (#34B27D)
        body: SafeArea(
          child: Stack(
            children: [
              // Centered logo and app name
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Replace this Container with your logo image or widget
                    Image.asset(
                      // placeholder icon for your logo
                      Assets.logo,
                      width: 80.w,
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      'WonderSolus',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom centered circular progress indicator
              Positioned(
                bottom: 32,
                left: 0,
                right: 0,
                child: Center(
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 4,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
