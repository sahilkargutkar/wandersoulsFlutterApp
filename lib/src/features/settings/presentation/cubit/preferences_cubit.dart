// import 'package:bloc/bloc.dart';
// import 'package:flutter/material.dart';

// import '../../../../config/model/user_perferce_model.dart';
// import '../../../../config/theme/app_theme.dart';

// class PreferencesCubit extends Cubit<UserPreferencesModel> {
//   PreferencesCubit()
//     : super(
//        UserPreferencesModel(
//           theme: ThemeMode.system,
//           language: AppLanguage.en,
//           distanceUnit: DistanceUnit.km,
//           temperatureUnit: TemperatureUnit.celsius,
//         ),
//       );

//   void changeTheme(AppTheme theme) {
//     print( theme.toString())
//     emit(state.copyWith(theme: theme.toString()));
//   }

//   void changeLanguage(AppLanguage language) {
//     emit(state.copyWith(language: language));
//   }

//   void changeDistanceUnit(DistanceUnit unit) {
//     emit(state.copyWith(distanceUnit: unit));
//   }

//   void changeTemperatureUnit(TemperatureUnit unit) {
//     emit(state.copyWith(temperatureUnit: unit));
//   }
// }
