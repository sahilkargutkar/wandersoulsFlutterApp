import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  final SharedPreferences _prefs;
  static const String _themeKey = 'is_dark_mode';

  ThemeCubit(this._prefs) : super(ThemeMode.system) {
    _loadTheme();
  }

  void _loadTheme() {
    final isDark = _prefs.getBool(_themeKey);
    if (isDark != null) {
      emit(isDark ? ThemeMode.dark : ThemeMode.light);
    } else {
      emit(ThemeMode.system);
    }
  }

  void toggleTheme(bool isDark) {
    _prefs.setBool(_themeKey, isDark);
    emit(isDark ? ThemeMode.dark : ThemeMode.light);
  }
}
