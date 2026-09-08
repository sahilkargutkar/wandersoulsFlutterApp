import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wonder_souls/src/config/core/assets/assets.dart';
import 'package:wonder_souls/src/features/auth/presentation/cubit/isLoginCubit/is_login_cubit.dart';
import 'package:wonder_souls/src/features/auth/presentation/screens/boarding_screens.dart';
import 'package:wonder_souls/src/features/home/presentation/screens/home_bottom_bar.dart';

import 'package:go_router/go_router.dart';
import '../cubit/isLoginCubit/is_login_state.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const String routeName = "/";

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _pulseController;
  late Animation<double> _fadeIn;
  late Animation<double> _slideUp;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    // Entrance animations
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );
    _slideUp = Tween<double>(begin: 40.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    // Pulse animations for background circles & logo
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _pulse = Tween<double>(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );

    _controller.forward().then((_) {
      if (mounted) {
        _pulseController.repeat(reverse: true);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = context.read<IsLoginCubit>();
      if (cubit.state is IsLoggedIn || cubit.state is IsLoggedOut) {
        _navigateBasedOnState(cubit.state);
      }
    });
  }

  bool _hasNavigated = false;
  void _navigateBasedOnState(IsLoginState state) async {
    if (_hasNavigated) return;
    _hasNavigated = true;
    await Future.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;
    if (state is IsLoggedIn) {
      context.go(HomeBottomBar.routeName);
    } else if (state is IsLoggedOut) {
      context.go(BoardingScreens.routeName);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<IsLoginCubit, IsLoginState>(
      listener: (context, state) {
        if (state is IsLoggedIn || state is IsLoggedOut) {
          _navigateBasedOnState(state);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, Color(0xFFF8FAFC)],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                // Soft pulsing decorative ambient shapes
                ScaleTransition(
                  scale: _pulse,
                  child: Stack(
                    children: [
                      Positioned(
                        top: -80.h,
                        right: -60.w,
                        child: Container(
                          width: 220.w,
                          height: 220.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF0D9F6E).withAlpha(12),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -100.h,
                        left: -80.w,
                        child: Container(
                          width: 260.w,
                          height: 260.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF0D9488).withAlpha(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Centered wide logo and tagline
                Center(
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _fadeIn.value,
                        child: Transform.translate(
                          offset: Offset(0, _slideUp.value),
                          child: child,
                        ),
                      );
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Wide prominent WanderSouls logo with gentle breath pulsing
                        ScaleTransition(
                          scale: _pulse,
                          child: Image.asset(
                            Assets.logo,
                            width: 280.w,
                            fit: BoxFit.contain,
                          ),
                        ),

                        SizedBox(height: 18.h),

                        Text(
                          'Your journey begins here',
                          style: TextStyle(
                            color: const Color(0xFF64748B),
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom loading indicator
                Positioned(
                  bottom: 40.h,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        color: const Color(0xFF0D9F6E),
                        strokeWidth: 2.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
