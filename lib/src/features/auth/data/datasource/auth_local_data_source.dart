import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wonder_souls/src/config/model/user_model.dart';

abstract class AuthLocalDataSource {
  Future<void> saveUser(UserModel? user);
  UserModel? getUser();
  Future<void> clearUser();

}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  static const _userKey = "user_data";

  final SharedPreferences prefs;

  AuthLocalDataSourceImpl(this.prefs);

  @override
  Future<void> saveUser(UserModel? user) async {
    final jsonString = jsonEncode(user?.toJson());
    await prefs.setString(_userKey, jsonString);
  }

  @override
  UserModel? getUser() {
    final jsonString = prefs.getString(_userKey);
    if (jsonString == null) return null;

    return UserModel.fromJson(jsonDecode(jsonString));
  }

  @override
  Future<void> clearUser() async {
    await prefs.remove(_userKey);
  }


}