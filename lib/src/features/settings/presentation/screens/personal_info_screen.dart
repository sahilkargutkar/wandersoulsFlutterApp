import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wonder_souls/src/config/core/injector/injector.dart';
import 'package:wonder_souls/src/config/core/services/api_services.dart';
import 'package:wonder_souls/src/config/model/failure.dart';
import 'package:wonder_souls/src/config/model/success.dart';
import 'package:wonder_souls/src/config/model/user_model.dart';
import 'package:wonder_souls/src/config/model/user_perferce_model.dart';
import 'package:wonder_souls/src/config/utils/app_toast.dart';
import 'package:wonder_souls/src/config/utils/common_widgets/common_button.dart';
import 'package:wonder_souls/src/config/utils/common_widgets/common_text_form_field.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_text.dart';
import 'package:wonder_souls/src/features/auth/data/datasource/auth_local_data_source.dart';

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
  late TextEditingController _countryController;
  late TextEditingController _languageController;
  late TextEditingController _currencyController;

  File? _pickedProfileImage;
  String? _existingProfilePicUrl;

  bool _loading = false;
  bool _saving = false;
  UserModel? _user;

  final List<String> _languages = [
    "English",
    "Spanish",
    "French",
    "German",
    "Italian",
    "Portuguese",
    "Hindi",
    "Japanese",
    "Chinese",
    "Arabic",
    "Russian",
    "Korean",
    "Dutch",
    "Turkish",
    "Swedish",
    "Polish",
    "Indonesian",
    "Vietnamese",
    "Thai",
  ];

  final List<String> _currencies = [
    "USD",
    "EUR",
    "GBP",
    "INR",
    "JPY",
    "AUD",
    "CAD",
    "CHF",
    "SGD",
    "AED",
    "CNY",
    "NZD",
    "BRL",
    "ZAR",
    "SEK",
    "KRW",
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _usernameController = TextEditingController();
    _emailController = TextEditingController();
    _countryController = TextEditingController();
    _languageController = TextEditingController(text: "English");
    _currencyController = TextEditingController(text: "USD");

    _loadLocalUser();
    _fetchUserProfile();
  }

  void _loadLocalUser() {
    final cachedUser = _localDataSource.getUser();
    if (cachedUser != null) {
      _applyUserData(cachedUser);
    }
  }

  void _applyUserData(UserModel user) {
    String resolvedUsername = user.userName ?? "";
    if (resolvedUsername.isEmpty) {
      if (user.email != null && user.email!.contains('@')) {
        resolvedUsername = user.email!.split('@').first;
      } else if (user.name != null && user.name!.isNotEmpty) {
        resolvedUsername = user.name!.replaceAll(' ', '').toLowerCase();
      }
    }

    setState(() {
      _user = user;
      _nameController.text = user.name ?? "";
      _usernameController.text = resolvedUsername;
      _emailController.text = user.email ?? "";
      _countryController.text =
          user.country ?? user.preferences?.country ?? "";
      _languageController.text = user.preferences?.language ?? "English";
      _currencyController.text = user.defaultCurrency ?? "USD";
      _existingProfilePicUrl = user.profilePicture;
    });
  }

  Future<void> _fetchUserProfile() async {
    final cachedUser = _localDataSource.getUser();
    final userId = cachedUser?.id;
    if (userId == null || userId.isEmpty) return;

    setState(() => _loading = _user == null);

    try {
      final res = await _apiService.get<UserModel>(
        "/User/$userId",
        fromJson: (json) {
          final data =
              json is Map<String, dynamic> ? (json["data"] ?? json) : json;
          return UserModel.fromJson(data);
        },
      );

      if (res is Success<UserModel>) {
        await _localDataSource.saveUser(res.data);
        if (mounted) {
          _applyUserData(res.data);
          setState(() => _loading = false);
        }
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (e) {
      debugPrint("Failed to load user profile: $e");
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (picked != null) {
        setState(() {
          _pickedProfileImage = File(picked.path);
        });
      }
    } catch (e) {
      AppToast.error("Failed to pick image: $e");
    }
  }

  void _showImagePickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: context.borderColor.withAlpha(100),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                16.h.verticalSpace,
                Text(
                  "Profile Photo",
                  style: context.text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                20.h.verticalSpace,
                ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(10.r),
                    decoration: BoxDecoration(
                      color: context.primary.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      color: context.primary,
                      size: 22.sp,
                    ),
                  ),
                  title: Text(
                    "Take Photo",
                    style: context.text.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(10.r),
                    decoration: BoxDecoration(
                      color: context.primary.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.photo_library_rounded,
                      color: context.primary,
                      size: 22.sp,
                    ),
                  ),
                  title: Text(
                    "Choose from Gallery",
                    style: context.text.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                if (_pickedProfileImage != null ||
                    (_existingProfilePicUrl != null &&
                        _existingProfilePicUrl!.isNotEmpty)) ...[
                  ListTile(
                    leading: Container(
                      padding: EdgeInsets.all(10.r),
                      decoration: BoxDecoration(
                        color: context.colors.error.withAlpha(20),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        color: context.colors.error,
                        size: 22.sp,
                      ),
                    ),
                    title: Text(
                      "Remove Photo",
                      style: context.text.bodyMedium?.copyWith(
                        color: context.colors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _pickedProfileImage = null;
                        _existingProfilePicUrl = "";
                      });
                    },
                  ),
                ],
                8.h.verticalSpace,
              ],
            ),
          ),
        );
      },
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
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              final filteredItems = items
                  .where(
                    (item) =>
                        item.toLowerCase().contains(searchQuery.toLowerCase()),
                  )
                  .toList();
              return DraggableScrollableSheet(
                initialChildSize: 0.6,
                minChildSize: 0.4,
                maxChildSize: 0.9,
                expand: false,
                builder: (context, scrollController) {
                  return Column(
                    children: [
                      16.h.verticalSpace,
                      Container(
                        width: 40.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: context.borderColor.withAlpha(100),
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                      16.h.verticalSpace,
                      Text(
                        title,
                        style: context.text.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      16.h.verticalSpace,
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
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              size: 20.sp,
                              color: context.onSurfaceVariant,
                            ),
                            filled: true,
                            fillColor: context.mutedBackground,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 12.h,
                            ),
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
                      16.h.verticalSpace,
                      Expanded(
                        child: ListView.separated(
                          controller: scrollController,
                          padding: EdgeInsets.symmetric(
                            horizontal: 20.w,
                            vertical: 8.h,
                          ),
                          itemCount: filteredItems.length,
                          separatorBuilder: (context, index) =>
                              Divider(color: context.borderColor.withAlpha(50)),
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

  void _openCountryPicker() {
    showCountryPicker(
      context: context,
      showPhoneCode: false,
      countryListTheme: CountryListThemeData(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24.r),
        ),
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
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 20.sp,
            color: context.onSurfaceVariant,
          ),
          filled: true,
          fillColor: context.mutedBackground,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 12.h,
          ),
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
        });
      },
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = _user?.id;
    if (userId == null || userId.isEmpty) {
      AppToast.error("User ID not found. Please log in again.");
      return;
    }

    setState(() => _saving = true);

    final String finalProfilePicture = _pickedProfileImage != null
        ? _pickedProfileImage!.path
        : (_existingProfilePicUrl ?? "");

    final updatedPreferences =
        (_user?.preferences ?? const UserPreferencesModel()).copyWith(
      language: _languageController.text.trim(),
      country: _countryController.text.trim(),
    );

    final updatedUser = (_user ?? const UserModel()).copyWith(
      name: _nameController.text.trim(),
      userName: _usernameController.text.trim(),
      defaultCurrency: _currencyController.text.trim(),
      country: _countryController.text.trim(),
      profilePicture: finalProfilePicture,
      preferences: updatedPreferences,
    );

    try {
      final res = await _apiService.put<dynamic>(
        "/User/$userId",
        data: updatedUser.toJson(),
        fromJson: (d) => d,
      );

      if (res is Success) {
        await _localDataSource.saveUser(updatedUser);
        AppToast.success("Profile updated successfully!");
        if (mounted) {
          Navigator.pop(context, true);
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

  Widget _buildAvatar() {
    ImageProvider? imageProvider;
    if (_pickedProfileImage != null) {
      imageProvider = FileImage(_pickedProfileImage!);
    } else if (_existingProfilePicUrl != null &&
        _existingProfilePicUrl!.isNotEmpty) {
      if (_existingProfilePicUrl!.startsWith("http://") ||
          _existingProfilePicUrl!.startsWith("https://")) {
        imageProvider = CachedNetworkImageProvider(_existingProfilePicUrl!);
      } else if (File(_existingProfilePicUrl!).existsSync()) {
        imageProvider = FileImage(File(_existingProfilePicUrl!));
      }
    }

    return Center(
      child: Stack(
        children: [
          Container(
            width: 104.r,
            height: 104.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: context.primary.withAlpha(50),
                width: 3.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: context.primary.withAlpha(25),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 48.r,
              backgroundColor: context.mutedBackground,
              backgroundImage: imageProvider,
              child: imageProvider == null
                  ? Icon(
                      Icons.person_rounded,
                      size: 52.r,
                      color: context.primary.withAlpha(160),
                    )
                  : null,
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _showImagePickerSheet,
              child: Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: context.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: context.surface,
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: context.primary.withAlpha(60),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.white,
                  size: 16.sp,
                ),
              ),
            ),
          ),
        ],
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

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _countryController.dispose();
    _languageController.dispose();
    _currencyController.dispose();
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
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: 24.w,
                  vertical: 16.h,
                ),
                children: [
                  _buildAvatar(),
                  8.h.verticalSpace,
                  Center(
                    child: TextButton(
                      onPressed: _showImagePickerSheet,
                      child: Text(
                        "Change Profile Photo",
                        style: context.text.bodyMedium?.copyWith(
                          color: context.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  20.h.verticalSpace,

                  // Full Name
                  _buildFieldLabel("Full Name"),
                  8.h.verticalSpace,
                  CommonTextFormField(
                    controller: _nameController,
                    hintText: "Enter your full name",
                    prefixIcon: Icon(
                      Icons.person_outline_rounded,
                      size: 20.sp,
                      color: context.onSurfaceVariant,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Name cannot be empty";
                      }
                      return null;
                    },
                  ),
                  18.h.verticalSpace,

                  // Username (read-only)
                  _buildFieldLabel("Username"),
                  8.h.verticalSpace,
                  CommonTextFormField(
                    controller: _usernameController,
                    readOnly: true,
                    hintText: "Enter your username",
                    prefixIcon: Icon(
                      Icons.alternate_email_rounded,
                      size: 20.sp,
                      color: context.onSurfaceVariant,
                    ),
                    suffixIcon: Icon(
                      Icons.lock_outline_rounded,
                      size: 18.sp,
                      color: context.onSurfaceVariant.withAlpha(140),
                    ),
                  ),
                  18.h.verticalSpace,

                  // Email Address (read-only)
                  _buildFieldLabel("Email Address"),
                  8.h.verticalSpace,
                  CommonTextFormField(
                    controller: _emailController,
                    readOnly: true,
                    hintText: "Enter email address",
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      size: 20.sp,
                      color: context.onSurfaceVariant,
                    ),
                    suffixIcon: Icon(
                      Icons.lock_outline_rounded,
                      size: 18.sp,
                      color: context.onSurfaceVariant.withAlpha(140),
                    ),
                  ),
                  18.h.verticalSpace,

                  // Country
                  _buildFieldLabel("Country"),
                  8.h.verticalSpace,
                  GestureDetector(
                    onTap: _openCountryPicker,
                    child: AbsorbPointer(
                      child: CommonTextFormField(
                        controller: _countryController,
                        hintText: "Select your country",
                        prefixIcon: Icon(
                          Icons.public_rounded,
                          size: 20.sp,
                          color: context.onSurfaceVariant,
                        ),
                        suffixIcon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: context.onSurfaceVariant,
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? "Country is required"
                            : null,
                      ),
                    ),
                  ),
                  18.h.verticalSpace,

                  // Language
                  _buildFieldLabel("Language"),
                  8.h.verticalSpace,
                  GestureDetector(
                    onTap: () {
                      _showSelectionPicker(
                        context: context,
                        title: "Select Language",
                        items: _languages,
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
                        prefixIcon: Icon(
                          Icons.language_rounded,
                          size: 20.sp,
                          color: context.onSurfaceVariant,
                        ),
                        suffixIcon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: context.onSurfaceVariant,
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? "Language is required"
                            : null,
                      ),
                    ),
                  ),
                  18.h.verticalSpace,

                  // Default Currency
                  _buildFieldLabel("Default Currency"),
                  8.h.verticalSpace,
                  GestureDetector(
                    onTap: () {
                      _showSelectionPicker(
                        context: context,
                        title: "Select Currency",
                        items: _currencies,
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
                        prefixIcon: Icon(
                          Icons.payments_outlined,
                          size: 20.sp,
                          color: context.onSurfaceVariant,
                        ),
                        suffixIcon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: context.onSurfaceVariant,
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? "Currency is required"
                            : null,
                      ),
                    ),
                  ),
                  36.h.verticalSpace,

                  // Save Profile Button
                  CommonButton(
                    title: "Save Profile",
                    isLoading: _saving,
                    onPressed: _saveProfile,
                  ),
                  24.h.verticalSpace,
                ],
              ),
            ),
    );
  }
}
