import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:country_picker/country_picker.dart';
import 'package:wonder_souls/src/config/utils/app_toast.dart';
import 'package:wonder_souls/src/config/utils/common_widgets/app_search_bar.dart';
import 'package:wonder_souls/src/config/utils/common_widgets/common_button.dart';
import 'package:wonder_souls/src/config/utils/common_widgets/common_text_form_field.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_text.dart';
import 'package:wonder_souls/src/features/auth/presentation/cubit/signup/signup_cubit.dart';
import 'package:wonder_souls/src/features/auth/presentation/screens/login_screen.dart';
import 'package:go_router/go_router.dart';

class SignupScreen extends StatefulWidget {
  static const String routeName = "/SignupScreen";
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  int _currentStep = 0;
  final PageController _pageController = PageController();

  // Step 1: Travel Preferences
  final List<String> _allPreferences = [
    'Adventure Travel',
    'City Breaks',
    'Cultural Exploration',
    'Glamping',
    'Beach Vacations',
    'Nature Escapes',
    'Relaxing Getaways',
    'Road Trips',
    'Food Tourism',
    'Backpacking',
    'Cruise Vacations',
    'Staycations',
    'Skiing/Snowboarding',
    'Wine Tours',
    'Wildlife Safaris',
    'Art Galleries',
  ];
  final List<String> _selectedPreferences = [];

  // Step 3: Personal Info
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _currencyController = TextEditingController();
  final TextEditingController _languageController = TextEditingController();
  String _phoneCode = '';
  File? _profileImage;

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  void _submitRegistration() {
    if (_formKey.currentState!.validate()) {
      context.read<SignUpCubit>().registerUser(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        country: _countryController.text,
        phone: '+$_phoneCode${_phoneController.text}',
        preferences: _selectedPreferences,
        currency: _currencyController.text.isNotEmpty ? _currencyController.text : 'USD',
        language: _languageController.text.isNotEmpty ? _languageController.text : 'English',
        profilePicturePath: _profileImage?.path,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SignUpCubit, SignUpState>(
      listener: (context, state) {
        if (state is SignUpSuccess) {
          _nextStep(); // Move to success screen
        } else if (state is SignUpFailure) {
          AppToast.error(state.message);
        }
      },
      builder: (context, state) {
        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                children: [
                  SizedBox(height: 16.h),
                  // App Bar / Progress indicator
                  Row(
                    children: [
                      if (_currentStep < 2)
                        GestureDetector(
                          onTap: () {
                            if (_currentStep > 0) {
                              setState(() => _currentStep--);
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeInOutCubic,
                              );
                            } else {
                              Navigator.pop(context);
                            }
                          },
                          child: Container(
                            width: 40.w,
                            height: 40.w,
                            decoration: BoxDecoration(
                              color: context.mutedBackground,
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 18.sp,
                              color: context.onSurface,
                            ),
                          ),
                        ),
                      if (_currentStep < 2) ...[
                        SizedBox(width: 16.w),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: (_currentStep + 1) / 2,
                              backgroundColor: context.mutedBackground,
                              color: context.primary,
                              minHeight: 6,
                            ),
                          ),
                        ),
                        SizedBox(width: 56.w), // Balance back button
                      ],
                    ],
                  ),
                  SizedBox(height: 20.h),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildStep2TravelPreferences(),
                        _buildStep3PersonalInfo(state),
                        _buildStep4Success(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStep2TravelPreferences() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Travel preferences ✈️",
          style: context.text.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          "Tell us your travel preferences, and we'll tailor recommendations to your style.",
          style: context.text.bodyMedium?.copyWith(
            color: context.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        SizedBox(height: 20.h),

        // Using consistent AppSearchBar
        AppSearchBar(
          hintText: "Search travel preferences",
        ),

        SizedBox(height: 20.h),
        Expanded(
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 8.w,
              runSpacing: 10.h,
              children: _allPreferences.map((pref) {
                final isSelected = _selectedPreferences.contains(pref);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedPreferences.remove(pref);
                      } else {
                        _selectedPreferences.add(pref);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 10.h,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? context.primary.withAlpha(20)
                          : context.mutedBackground,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: isSelected
                            ? context.primary
                            : context.borderColor.withAlpha(40),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected) ...[
                          Icon(
                            Icons.check_rounded,
                            size: 16.sp,
                            color: context.primary,
                          ),
                          SizedBox(width: 6.w),
                        ],
                        Text(
                          pref,
                          style: context.text.bodyMedium?.copyWith(
                            color: isSelected
                                ? context.primary
                                : context.onSurface,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        SizedBox(height: 12.h),
        CommonButton(
          title: "Continue",
          onPressed: _selectedPreferences.isNotEmpty ? _nextStep : null,
        ),
        SizedBox(height: 20.h),
      ],
    );
  }

  Widget _buildStep3PersonalInfo(SignUpState state) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Add a personal touch 👤",
              style: context.text.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              "To enhance your travel journey, we'd love to know more about you.",
              style: context.text.bodyMedium?.copyWith(
                color: context.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            SizedBox(height: 28.h),

            // Profile image
            Center(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: context.primary.withAlpha(40),
                        width: 3,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 48.r,
                      backgroundColor: context.mutedBackground,
                      backgroundImage: _profileImage != null
                          ? FileImage(_profileImage!)
                          : null,
                      child: _profileImage == null
                          ? Icon(
                              Icons.person_rounded,
                              size: 44.r,
                              color: context.onSurfaceVariant.withAlpha(100),
                            )
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: context.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: context.primary.withAlpha(40),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 28.h),

            // Form fields with labels
            _buildFieldLabel("Full Name"),
            SizedBox(height: 6.h),
            CommonTextFormField(
              controller: _nameController,
              hintText: "Andrew Andey",
              prefixIcon: Icon(Icons.person_outline, size: 20.sp, color: context.onSurfaceVariant),
              validator: (v) => v!.isEmpty ? "Required" : null,
            ),
            SizedBox(height: 16.h),

            _buildFieldLabel("Email"),
            SizedBox(height: 6.h),
            CommonTextFormField(
              controller: _emailController,
              hintText: "andrew@yourdomain.com",
              prefixIcon: Icon(Icons.email_outlined, size: 20.sp, color: context.onSurfaceVariant),
              validator: (v) => v!.isEmpty || !v.contains('@')
                  ? "Valid email required"
                  : null,
            ),
            SizedBox(height: 16.h),

            _buildFieldLabel("Password"),
            SizedBox(height: 6.h),
            CommonTextFormField(
              controller: _passwordController,
              hintText: "Enter your password",
              obscureText: true,
              prefixIcon: Icon(Icons.lock_outline, size: 20.sp, color: context.onSurfaceVariant),
              validator: (v) => v!.length < 6 ? "Minimum 6 characters" : null,
            ),
            SizedBox(height: 16.h),

            _buildFieldLabel("Country"),
            SizedBox(height: 6.h),
            GestureDetector(
              onTap: () {
                showCountryPicker(
                  context: context,
                  showPhoneCode: true,
                  countryListTheme: CountryListThemeData(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
                    backgroundColor: context.surface,
                    searchTextStyle: context.text.bodyMedium?.copyWith(
                      color: context.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                    inputDecoration: InputDecoration(
                      hintText: "Search country",
                      hintStyle: context.text.bodyMedium?.copyWith(
                        color: context.onSurfaceVariant.withAlpha(140),
                      ),
                      prefixIcon: Icon(Icons.search_rounded, size: 20.sp, color: context.onSurfaceVariant),
                      filled: true,
                      fillColor: context.mutedBackground,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(
                          color: context.borderColor.withAlpha(50),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(
                          color: context.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  onSelect: (Country country) {
                    setState(() {
                      _countryController.text = country.name;
                      _phoneCode = country.phoneCode;
                    });
                  },
                );
              },
              child: AbsorbPointer(
                child: CommonTextFormField(
                  controller: _countryController,
                  hintText: "Select your country",
                  prefixIcon: Icon(Icons.public, size: 20.sp, color: context.onSurfaceVariant),
                  suffixIcon: Icon(Icons.keyboard_arrow_down_rounded, color: context.onSurfaceVariant),
                  validator: (v) => v!.isEmpty ? "Required" : null,
                ),
              ),
            ),
            SizedBox(height: 16.h),

            _buildFieldLabel("Phone Number"),
            SizedBox(height: 6.h),
            CommonTextFormField(
              controller: _phoneController,
              hintText: "Phone Number",
              keyboardType: TextInputType.phone,
              prefixIcon: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.phone_outlined, size: 20.sp, color: context.onSurfaceVariant),
                    if (_phoneCode.isNotEmpty) ...[
                      SizedBox(width: 8.w),
                      Text(
                        '+$_phoneCode',
                        style: context.text.bodyMedium?.copyWith(
                          color: context.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Container(
                        width: 1,
                        height: 20.h,
                        color: context.borderColor.withAlpha(50),
                      ),
                      SizedBox(width: 4.w),
                    ],
                  ],
                ),
              ),
              validator: (v) => v!.isEmpty ? "Required" : null,
            ),
            SizedBox(height: 16.h),

            _buildFieldLabel("Default Currency"),
            SizedBox(height: 6.h),
            GestureDetector(
              onTap: () {
                _showSelectionPicker(
                  context: context,
                  title: "Select Currency",
                  items: ['USD', 'EUR', 'GBP', 'INR', 'AUD', 'CAD', 'JPY'],
                  onSelect: (val) {
                    setState(() {
                      _currencyController.text = val;
                    });
                  },
                );
              },
              child: AbsorbPointer(
                child: CommonTextFormField(
                  controller: _currencyController,
                  hintText: "Select Currency",
                  prefixIcon: Icon(Icons.monetization_on_outlined, size: 20.sp, color: context.onSurfaceVariant),
                  suffixIcon: Icon(Icons.keyboard_arrow_down_rounded, color: context.onSurfaceVariant),
                  validator: (v) => v!.isEmpty ? "Required" : null,
                ),
              ),
            ),
            SizedBox(height: 16.h),

            _buildFieldLabel("Language"),
            SizedBox(height: 6.h),
            GestureDetector(
              onTap: () {
                _showSelectionPicker(
                  context: context,
                  title: "Select Language",
                  items: ['English', 'Spanish', 'French', 'German', 'Hindi', 'Chinese', 'Japanese'],
                  onSelect: (val) {
                    setState(() {
                      _languageController.text = val;
                    });
                  },
                );
              },
              child: AbsorbPointer(
                child: CommonTextFormField(
                  controller: _languageController,
                  hintText: "Select Language",
                  prefixIcon: Icon(Icons.language_outlined, size: 20.sp, color: context.onSurfaceVariant),
                  suffixIcon: Icon(Icons.keyboard_arrow_down_rounded, color: context.onSurfaceVariant),
                  validator: (v) => v!.isEmpty ? "Required" : null,
                ),
              ),
            ),
            SizedBox(height: 28.h),
            CommonButton(
              title: "Create Account",
              isLoading: state is SignUpLoading,
              onPressed: _submitRegistration,
            ),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: context.text.bodyMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: context.onSurface,
      ),
    );
  }

  void _showSelectionPicker({
    required BuildContext context,
    required String title,
    required List<String> items,
    required Function(String) onSelect,
  }) {
    String searchQuery = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              final filteredItems = items
                  .where((item) => item.toLowerCase().contains(searchQuery.toLowerCase()))
                  .toList();
              return DraggableScrollableSheet(
                initialChildSize: 0.6,
                minChildSize: 0.4,
                maxChildSize: 0.9,
                expand: false,
                builder: (context, scrollController) {
                  return Column(
                    children: [
                      SizedBox(height: 16.h),
                      Container(
                        width: 40.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: context.borderColor.withAlpha(100),
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        title,
                        style: context.text.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        child: TextField(
                          style: context.text.bodyMedium?.copyWith(
                            color: context.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            hintText: "Search...",
                            hintStyle: context.text.bodyMedium?.copyWith(
                              color: context.onSurfaceVariant.withAlpha(140),
                            ),
                            prefixIcon: Icon(Icons.search_rounded, size: 20.sp, color: context.onSurfaceVariant),
                            filled: true,
                            fillColor: context.mutedBackground,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide(
                                color: context.borderColor.withAlpha(50),
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide(
                                color: context.primary,
                                width: 1.5,
                              ),
                            ),
                          ),
                          onChanged: (val) {
                            setModalState(() {
                              searchQuery = val;
                            });
                          },
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Expanded(
                        child: ListView.separated(
                          controller: scrollController,
                          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                          itemCount: filteredItems.length,
                          separatorBuilder: (context, index) => Divider(color: context.borderColor.withAlpha(50)),
                          itemBuilder: (context, index) {
                            final item = filteredItems[index];
                            return ListTile(
                              title: Text(
                                item,
                                style: context.text.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              onTap: () {
                                onSelect(item);
                                Navigator.pop(context);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildStep4Success() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Spacer(),

        // Animated checkmark
        Container(
          width: 100.w,
          height: 100.w,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                context.primary,
                context.primary.withAlpha(200),
              ],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: context.primary.withAlpha(40),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const Icon(
            Icons.check_rounded,
            color: Colors.white,
            size: 48,
          ),
        ),

        SizedBox(height: 28.h),

        Text(
          "You're all set! 🎉",
          style: context.text.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),

        SizedBox(height: 12.h),

        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Text(
            "Welcome to the WonderSolus community! Your personalized travel experiences await.",
            textAlign: TextAlign.center,
            style: context.text.bodyLarge?.copyWith(
              color: context.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ),

        const Spacer(),

        CommonButton(
          title: "Start Exploring",
          icon: Icons.arrow_forward_rounded,
          onPressed: () {
            context.go(LoginScreen.routeName);
          },
        ),
        SizedBox(height: 24.h),
      ],
    );
  }
}
