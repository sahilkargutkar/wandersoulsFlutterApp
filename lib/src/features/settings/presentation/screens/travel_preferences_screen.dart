import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wonder_souls/src/config/core/injector/injector.dart';
import 'package:wonder_souls/src/features/auth/data/datasource/auth_remote_data_source.dart';
import 'package:wonder_souls/src/features/auth/data/model1/travel_preference_model.dart';
import 'package:wonder_souls/src/config/model/success.dart';
import 'package:wonder_souls/src/config/model/failure.dart';
import 'package:wonder_souls/src/config/utils/app_toast.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_text.dart';
import 'package:wonder_souls/src/config/utils/common_widgets/common_button.dart';

class TravelPreferencesScreen extends StatefulWidget {
  const TravelPreferencesScreen({super.key});

  static const String routeName = "/TravelPreferencesScreen";

  @override
  State<TravelPreferencesScreen> createState() =>
      _TravelPreferencesScreenState();
}

class _TravelPreferencesScreenState extends State<TravelPreferencesScreen> {
  final AuthRemoteDataSource _authRemoteDataSource = sl<AuthRemoteDataSource>();

  bool _loading = true;
  bool _saving = false;
  TravelPreferenceModel? _preference;
  bool _isNew = true;

  // Options lists
  final List<String> _travelStyles = [
    "Explorer",
    "Relaxation",
    "Adventure",
    "Culture",
    "Business",
    "Shopping",
  ];
  final List<String> _budgetPreferences = [
    "Cheap",
    "Moderate",
    "Luxury",
    "Flexible",
  ];
  final List<String> _accommodationPreferences = [
    "Hotel",
    "Hostel",
    "Resort",
    "Villa",
    "Apartment",
  ];

  final List<String> _allCategories = [
    "Landmark",
    "Food",
    "Adventure",
    "Culture",
    "Shopping",
    "Nature",
    "Entertainment",
  ];
  final List<String> _allDietaries = [
    "Vegetarian",
    "Vegan",
    "Gluten-Free",
    "Halal",
    "Kosher",
    "Dairy-Free",
  ];

  // Selected values
  String _selectedStyle = "Explorer";
  String _selectedBudget = "Moderate";
  String _selectedAcc = "Hotel";
  final List<String> _selectedCategories = [];
  final List<String> _selectedDietaries = [];

  @override
  void initState() {
    super.initState();
    _fetchPreferences();
  }

  Future<void> _fetchPreferences() async {
    setState(() => _loading = true);
    try {
      final res = await _authRemoteDataSource.getPreferences();
      if (res is Success<TravelPreferenceModel>) {
        final pref = res.data;
        setState(() {
          _preference = pref;
          _isNew = pref.id == null || pref.id!.isEmpty;
          _selectedStyle = pref.travelStyle ?? "Explorer";
          _selectedBudget = pref.budgetPreference ?? "Moderate";
          _selectedAcc = pref.accommodationPreference ?? "Hotel";
          _selectedCategories.clear();
          _selectedCategories.addAll(pref.preferredCategories);
          _selectedDietaries.clear();
          _selectedDietaries.addAll(pref.dietaryRestrictions);
          _loading = false;
        });
      } else {
        // Preferences do not exist yet
        setState(() {
          _isNew = true;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint("Failed to load preferences: $e");
      setState(() {
        _isNew = true;
        _loading = false;
      });
    }
  }

  Future<void> _savePreferences() async {
    setState(() => _saving = true);

    final prefModel = TravelPreferenceModel(
      id: _preference?.id,
      userId: _preference?.userId,
      travelStyle: _selectedStyle,
      preferredCategories: _selectedCategories,
      budgetPreference: _selectedBudget,
      accommodationPreference: _selectedAcc,
      dietaryRestrictions: _selectedDietaries,
    );

    try {
      if (_isNew) {
        final res = await _authRemoteDataSource.savePreferences(prefModel);
        if (res is Success) {
          AppToast.success("Preferences saved successfully!");
          if (mounted) Navigator.pop(context);
        } else if (res is Failure) {
          AppToast.error(res.message);
        }
      } else {
        final prefId = _preference?.id ?? "";
        final res = await _authRemoteDataSource.updatePreferences(
          prefId,
          prefModel,
        );
        if (res is Success) {
          AppToast.success("Preferences updated successfully!");
          if (mounted) Navigator.pop(context);
        } else if (res is Failure) {
          AppToast.error(res.message);
        }
      }
    } catch (e) {
      AppToast.error("Failed to save preferences: $e");
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toggleCategory(String category) {
    setState(() {
      if (_selectedCategories.contains(category)) {
        _selectedCategories.remove(category);
      } else {
        _selectedCategories.add(category);
      }
    });
  }

  void _toggleDietary(String dietary) {
    setState(() {
      if (_selectedDietaries.contains(dietary)) {
        _selectedDietaries.remove(dietary);
      } else {
        _selectedDietaries.add(dietary);
      }
    });
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
          "Travel Preferences",
          style: context.text.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: context.primary))
          : ListView(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
              children: [
                Text(
                  "Customize Your Travel Style",
                  style: context.text.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.onSurface,
                  ),
                ),
                8.h.verticalSpace,
                Text(
                  "Configure your defaults to help our AI craft the perfect, personalized itineraries for your adventures.",
                  style: context.text.bodyMedium?.copyWith(
                    color: context.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                24.h.verticalSpace,

                // Travel Style
                _buildLabel("Travel Style"),
                8.h.verticalSpace,
                DropdownButtonFormField<String>(
                  initialValue: _selectedStyle,
                  decoration: _buildInputDecoration(),
                  items: _travelStyles
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (val) => {
                    if (val != null) setState(() => _selectedStyle = val),
                  },
                ),
                20.h.verticalSpace,

                // Budget Preference
                _buildLabel("Budget Preference"),
                8.h.verticalSpace,
                DropdownButtonFormField<String>(
                  initialValue: _selectedBudget,
                  decoration: _buildInputDecoration(),
                  items: _budgetPreferences
                      .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                      .toList(),
                  onChanged: (val) => {
                    if (val != null) setState(() => _selectedBudget = val),
                  },
                ),
                20.h.verticalSpace,

                // Accommodation Preference
                _buildLabel("Accommodation Type"),
                8.h.verticalSpace,
                DropdownButtonFormField<String>(
                  initialValue: _selectedAcc,
                  decoration: _buildInputDecoration(),
                  items: _accommodationPreferences
                      .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                      .toList(),
                  onChanged: (val) => {
                    if (val != null) setState(() => _selectedAcc = val),
                  },
                ),
                24.h.verticalSpace,

                // Preferred Categories
                _buildLabel("Preferred Categories"),
                8.h.verticalSpace,
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: _allCategories.map((cat) {
                    final isSelected = _selectedCategories.contains(cat);
                    return ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      onSelected: (_) => _toggleCategory(cat),
                      selectedColor: context.colors.primary,
                      backgroundColor: context.mutedBackground,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : context.onSurface,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.r),
                        side: BorderSide.none,
                      ),
                    );
                  }).toList(),
                ),
                24.h.verticalSpace,

                // Dietary Restrictions
                _buildLabel("Dietary Restrictions"),
                8.h.verticalSpace,
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: _allDietaries.map((diet) {
                    final isSelected = _selectedDietaries.contains(diet);
                    return ChoiceChip(
                      label: Text(diet),
                      selected: isSelected,
                      onSelected: (_) => _toggleDietary(diet),
                      selectedColor: context.colors.primary,
                      backgroundColor: context.mutedBackground,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : context.onSurface,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.r),
                        side: BorderSide.none,
                      ),
                    );
                  }).toList(),
                ),
                40.h.verticalSpace,

                CommonButton(
                  title: "Save Preferences",
                  isLoading: _saving,
                  onPressed: _savePreferences,
                ),
              ],
            ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: context.text.bodyMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: context.onSurface,
      ),
    );
  }

  InputDecoration _buildInputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: context.mutedBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.r),
        borderSide: BorderSide.none,
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
    );
  }
}
