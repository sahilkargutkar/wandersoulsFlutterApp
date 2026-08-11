import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wonder_souls/src/config/core/assets/assets.dart';
import 'package:wonder_souls/src/config/utils/app_toast.dart';
import 'package:wonder_souls/src/config/utils/validator.dart';
import 'package:wonder_souls/src/features/auth/presentation/cubit/login/auth_cubit.dart';
import 'package:wonder_souls/src/features/auth/presentation/cubit/login/auth_state.dart';
import 'package:wonder_souls/src/features/auth/presentation/widget/social_login_button_icon.dart';
import 'package:wonder_souls/src/features/home/presentation/screens/home_bottom_bar.dart';
import 'package:wonder_souls/src/config/utils/common_widgets/common_button.dart';
import 'package:wonder_souls/src/config/utils/common_widgets/common_text_form_field.dart';
import 'package:wonder_souls/src/config/utils/common_widgets/size.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_text.dart';
import 'package:go_router/go_router.dart';

import '../cubit/password/password_cubit.dart';
import 'package:wonder_souls/src/features/auth/presentation/screens/signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static const String routeName = "/LoginScreen";

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final TextEditingController usernameController;
  late final TextEditingController passwordController;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    usernameController = TextEditingController();
    passwordController = TextEditingController();
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          context.go(HomeBottomBar.routeName);
          AppToast.success("Login Successful");
        }
        if (state is AuthError) {
          AppToast.error(state.message);
        }
      },
      builder: (context, state) {
        return Scaffold(
          resizeToAvoidBottomInset: true,
          body: SafeArea(
            child: Stack(
              children: [
                // Decorative elements
                Positioned(
                  top: -50.h,
                  right: -50.w,
                  child: Container(
                    width: 180.w,
                    height: 180.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.primary.withAlpha(8),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -80.h,
                  left: -60.w,
                  child: Container(
                    width: 200.w,
                    height: 200.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.primary.withAlpha(6),
                    ),
                  ),
                ),

                // Main content
                SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: 0.h,
                      horizontal: 24.w,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        40.h.height,
                        // Logo
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22.r),
                            boxShadow: [
                              BoxShadow(
                                color: context.primary.withAlpha(20),
                                blurRadius: 24,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(22.r),
                            child: Image.asset(Assets.logo, width: 88.w),
                          ),
                        ),

                        SizedBox(height: 28.h),

                        Text(
                          "Welcome Back",
                          style: context.text.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        8.h.height,

                        Text(
                          "Your Passport to Adventure Awaits",
                          style: context.text.bodyLarge?.copyWith(
                            color: context.onSurfaceVariant.withAlpha(180),
                          ),
                          textAlign: TextAlign.center,
                        ),

                        36.h.height,

                        Form(
                          key: formKey,
                          child: Column(
                            children: [
                              CommonTextFormField(
                                hintText: 'Enter Email',
                                controller: usernameController,
                                prefixIcon: Icon(
                                  Icons.email_outlined,
                                  size: 20.sp,
                                  color: context.onSurfaceVariant,
                                ),
                                validator: (value) =>
                                    Validators.validateEmail(value),
                              ),
                              14.h.height,
                              BlocProvider(
                                create: (_) => PasswordCubit(),
                                child: BlocBuilder<PasswordCubit, bool>(
                                  builder: (context, obscure) {
                                    return CommonTextFormField(
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          obscure
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          size: 20.sp,
                                          color: context.onSurfaceVariant,
                                        ),
                                        onPressed: () {
                                          context
                                              .read<PasswordCubit>()
                                              .togglePassword();
                                        },
                                      ),
                                      prefixIcon: Icon(
                                        Icons.lock_outline,
                                        size: 20.sp,
                                        color: context.onSurfaceVariant,
                                      ),
                                      obscureText: obscure,
                                      hintText: 'Enter Password',
                                      controller: passwordController,
                                      validator: (value) =>
                                          Validators.validatePassword(value),
                                    );
                                  },
                                ),
                              ),

                              // Forgot password link
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {},
                                  child: Text(
                                    'Forgot Password?',
                                    style: context.text.bodySmall?.copyWith(
                                      color: context.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),

                              8.h.height,

                              CommonButton(
                                title: "Login",
                                isLoading: state is AuthLoading,
                                onPressed: () {
                                  FocusScope.of(context).unfocus();
                                  if (!(formKey.currentState?.validate() ??
                                      true)) {
                                    return;
                                  }
                                  context.read<AuthCubit>().login(
                                    usernameController.text,
                                    passwordController.text,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        28.h.height,

                        // OR divider
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 1,
                                color: context.borderColor.withAlpha(60),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.w),
                              child: Text(
                                "or continue with",
                                style: context.text.bodySmall?.copyWith(
                                  color: context.onSurfaceVariant.withAlpha(
                                    150,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 1,
                                color: context.borderColor.withAlpha(60),
                              ),
                            ),
                          ],
                        ),

                        24.h.height,

                        // Social login buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SocialLoginButtonIcon(
                              onPressed: () {},
                              icon: Image.asset(Assets.google, scale: 28),
                            ),
                            14.w.width,
                            SocialLoginButtonIcon(
                              onPressed: () {},
                              icon: Image.asset(
                                Assets.apple,
                                scale: 28,
                                color: context.onSurface,
                                colorBlendMode: BlendMode.srcIn,
                              ),
                            ),
                            14.w.width,
                            SocialLoginButtonIcon(
                              onPressed: () {},
                              icon: Image.asset(Assets.facebook, scale: 28),
                            ),
                            14.w.width,
                            SocialLoginButtonIcon(
                              onPressed: () {},
                              icon: Image.asset(Assets.twitter, scale: 28),
                            ),
                          ],
                        ),

                        24.h.height,

                        // Privacy & Terms
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              onPressed: () {
                                launchUrl(
                                  Uri.parse(
                                    "https://www.wanderingsouls.in/privacy-policy/",
                                  ),
                                  mode: LaunchMode.externalApplication,
                                );
                              },
                              child: Text(
                                'Privacy Policy',
                                style: context.text.bodySmall?.copyWith(
                                  color: context.onSurfaceVariant.withAlpha(
                                    160,
                                  ),
                                ),
                              ),
                            ),
                            Text(
                              '•',
                              style: context.text.bodySmall?.copyWith(
                                color: context.onSurfaceVariant.withAlpha(100),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                launchUrl(
                                  Uri.parse(
                                    "https://wanderingsouls.in/terms-and-conditions",
                                  ),
                                  mode: LaunchMode.externalApplication,
                                );
                              },
                              child: Text(
                                'Terms of Service',
                                style: context.text.bodySmall?.copyWith(
                                  color: context.onSurfaceVariant.withAlpha(
                                    160,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        12.h.height,

                        // Sign up link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account?",
                              style: context.text.bodyMedium?.copyWith(
                                color: context.onSurfaceVariant,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                context.push(SignupScreen.routeName);
                              },
                              child: Text(
                                'Sign Up',
                                style: context.text.titleSmall?.copyWith(
                                  color: context.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        20.h.height,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class SocialLoginButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget icon;
  final String text;

  const SocialLoginButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: context.mutedBackground,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: context.borderColor.withAlpha(40),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            SizedBox(width: 16.w),
            icon,
            Expanded(
              child: Center(
                child: Text(
                  text,
                  style: context.text.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SizedBox(width: 40.w),
          ],
        ),
      ),
    );
  }
}
