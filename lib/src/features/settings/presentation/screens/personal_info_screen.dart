import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wonder_souls/src/config/core/injector/injector.dart';
import 'package:wonder_souls/src/config/core/services/api_services.dart';
import 'package:wonder_souls/src/config/model/user_model.dart';
import 'package:wonder_souls/src/config/model/success.dart';
import 'package:wonder_souls/src/config/model/failure.dart';
import 'package:wonder_souls/src/config/utils/app_toast.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_text.dart';
import 'package:wonder_souls/src/features/auth/data/datasource/auth_local_data_source.dart';
import 'package:wonder_souls/src/config/utils/common_widgets/common_button.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  static const String routeName = "/PersonalInfoScreen";

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final AuthLocalDataSource _localDataSource = sl<AuthLocalDataSource>();
  final ApiService _apiService = sl<ApiService>();

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  String _selectedCurrency = "USD";

  bool _loading = false;
  bool _saving = false;
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _usernameController = TextEditingController();
    _emailController = TextEditingController();
    _loadLocalUser();
    _fetchUserProfile();
  }

  void _loadLocalUser() {
    final cachedUser = _localDataSource.getUser();
    if (cachedUser != null) {
      setState(() {
        _user = cachedUser;
        _nameController.text = cachedUser.name ?? "";
        _usernameController.text = cachedUser.userName ?? "";
        _emailController.text = cachedUser.email ?? "";
        _selectedCurrency = cachedUser.defaultCurrency ?? "USD";
      });
    }
  }

  Future<void> _fetchUserProfile() async {
    final cachedUser = _localDataSource.getUser();
    final userId = cachedUser?.id;
    if (userId == null || userId.isEmpty) return;

    setState(() => _loading = _user == null);

    try {
      final res = await _apiService.get<UserModel>(
        "/User/$userId",
        fromJson: (json) => UserModel.fromJson(json),
      );

      if (res is Success<UserModel>) {
        await _localDataSource.saveUser(res.data);
        if (mounted) {
          setState(() {
            _user = res.data;
            _nameController.text = res.data.name ?? "";
            _usernameController.text = res.data.userName ?? "";
            _emailController.text = res.data.email ?? "";
            _selectedCurrency = res.data.defaultCurrency ?? "USD";
            _loading = false;
          });
        }
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (e) {
      debugPrint("Failed to load user profile: $e");
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = _user?.id;
    if (userId == null || userId.isEmpty) return;

    setState(() => _saving = true);

    final updatedData = {
      "name": _nameController.text.trim(),
      "userName": _usernameController.text.trim(),
      "defaultCurrency": _selectedCurrency,
      "email": _emailController.text.trim(),
    };

    try {
      final res = await _apiService.put<dynamic>(
        "/User/$userId",
        data: updatedData,
        fromJson: (d) => d,
      );

      if (res is Success) {
        AppToast.success("Profile updated successfully!");
        final updatedUser = _user?.copyWith(
          name: _nameController.text.trim(),
          userName: _usernameController.text.trim(),
          defaultCurrency: _selectedCurrency,
        );
        if (updatedUser != null) {
          await _localDataSource.saveUser(updatedUser);
        }
        if (mounted) {
          Navigator.pop(context);
        }
      } else if (res is Failure) {
        AppToast.error(res.message);
      }
    } catch (e) {
      AppToast.error("Failed to update profile: $e");
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.surface,
      appBar: AppBar(
        backgroundColor: context.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: context.onSurface,
            size: 20.sp,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Personal Info",
          style: context.text.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: context.primary))
          : Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 50.r,
                      backgroundColor: context.colors.primary.withAlpha(20),
                      child: Icon(
                        Icons.person_rounded,
                        size: 50.sp,
                        color: context.colors.primary,
                      ),
                    ),
                  ),
                  32.h.verticalSpace,

                  Text(
                    "Full Name",
                    style: context.text.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.onSurface,
                    ),
                  ),
                  8.h.verticalSpace,
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: "Enter your full name",
                      filled: true,
                      fillColor: context.mutedBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.r),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 14.h,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Name cannot be empty";
                      }
                      return null;
                    },
                  ),
                  20.h.verticalSpace,

                  Text(
                    "Username",
                    style: context.text.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.onSurface,
                    ),
                  ),
                  8.h.verticalSpace,
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      hintText: "Enter your username",
                      filled: true,
                      fillColor: context.mutedBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.r),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 14.h,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Username cannot be empty";
                      }
                      return null;
                    },
                  ),
                  20.h.verticalSpace,

                  Text(
                    "Email Address",
                    style: context.text.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.onSurface,
                    ),
                  ),
                  8.h.verticalSpace,
                  TextFormField(
                    controller: _emailController,
                    readOnly: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: context.mutedBackground.withValues(alpha: 0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.r),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 14.h,
                      ),
                    ),
                  ),
                  20.h.verticalSpace,

                  Text(
                    "Default Currency",
                    style: context.text.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.onSurface,
                    ),
                  ),
                  8.h.verticalSpace,
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCurrency,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: context.mutedBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.r),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 14.h,
                      ),
                    ),
                    items: ["USD", "EUR", "GBP", "JPY", "INR", "AUD", "CAD"]
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedCurrency = val);
                      }
                    },
                  ),
                  40.h.verticalSpace,

                  CommonButton(
                    title: "Save Profile",
                    isLoading: _saving,
                    onPressed: _saveProfile,
                  ),
                ],
              ),
            ),
    );
  }
}
