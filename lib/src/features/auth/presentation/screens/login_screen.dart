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
import 'package:wonder_souls/src/config/utils/extensions/context_text.dart';

import '../cubit/password/password_cubit.dart';

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
          Navigator.pushReplacementNamed(context, HomeBottomBar.routeName);

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
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 0.h, horizontal: 20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    50.h.height,
                    // Logo
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20.r),
                      child: Image.asset(
                        // placeholder icon for your logo
                        Assets.logo,
                        width: 100.w,
                      ),
                    ),

                    SizedBox(height: 32.h),

                    Text(
                      "Let's Get Started!",
                      style: context.text.titleLarge?.copyWith(
                        fontSize: 36,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    12.h.height,

                    Text(
                      "Your Passport to Adventure Awaits",
                      style: context.text.labelMedium?.copyWith(
                        color: context.colors.onSurface.withAlpha(200),
                      ),
                      textAlign: TextAlign.center,
                    ),

                    40.h.height,

                    Form(
                      key: formKey,
                      child: Column(
                        children: [
                          CommonTextFormField(
                            hintText: 'Enter Email',
                            controller: usernameController,

                            validator: (value) =>
                                Validators.validateEmail(value),
                          ),
                          16.h.height,
                          BlocProvider(
                            create: (_) => PasswordCubit(),
                            child: BlocBuilder<PasswordCubit, bool>(
                              builder: (context, obscure) {
                                return CommonTextFormField(
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      obscure
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                    ),
                                    onPressed: () {
                                      context
                                          .read<PasswordCubit>()
                                          .togglePassword();
                                    },
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
                          24.h.height,
                          CommonButton(
                            title: "Login",
                            isLoading: state is AuthLoading,
                            onPressed: () {
                              FocusScope.of(context).unfocus();
                              if (!(formKey.currentState?.validate() ?? true)) {
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

                    32.h.height,
                    Row(
                      children: [
                        Flexible(
                          child: Divider(
                            color: context.colors.onSurface.withAlpha(100),
                          ),
                        ),
                        4.w.width,
                        Text("OR", style: context.text.labelSmall),
                        4.w.width,
                        Flexible(
                          child: Divider(
                            color: context.colors.onSurface.withAlpha(100),
                          ),
                        ),
                      ],
                    ),
                    24.h.height,

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SocialLoginButtonIcon(
                          onPressed: () {},
                          icon: Image.asset(Assets.google, scale: 28),
                        ),
                        16.w.width,
                        SocialLoginButtonIcon(
                          onPressed: () {},
                          icon: Image.asset(
                            Assets.apple,
                            scale: 28,
                            color: context.colors.onSurfaceVariant,
                            colorBlendMode: BlendMode.srcIn,
                          ),
                        ),
                        16.w.width,
                        SocialLoginButtonIcon(
                          onPressed: () {},
                          icon: Image.asset(Assets.facebook, scale: 28),
                        ),
                        16.w.width,
                        SocialLoginButtonIcon(
                          onPressed: () {},
                          icon: Image.asset(Assets.twitter, scale: 28),
                        ),
                      ],
                    ),

                    24.h.height,

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () {},
                          child: Text(
                            'Privacy Policy',
                            style: context.text.bodyMedium,
                          ),
                        ),
                        Text(' • ', style: context.text.bodyMedium),
                        TextButton(
                          onPressed: () {},
                          child: Text(
                            'Terms of Service',
                            style: context.text.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                    24.h.height,
                  ],
                ),
              ),
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
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
        height: 30.h,
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerHighest,

          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: context.colors.onSurface.withAlpha(100),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                icon,
                Expanded(
                  child: Center(
                    child: Text(
                      text,
                      style: context.text.titleMedium?.copyWith(
                        fontSize: 16,

                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
                28.w.width,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
