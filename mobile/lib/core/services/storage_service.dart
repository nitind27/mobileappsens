import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class StorageService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static Future<void> saveToken(String token) async {
    await init();
    await _prefs!.setString(AppConstants.tokenKey, token);
  }

  static String? getToken() {
    return _prefs?.getString(AppConstants.tokenKey);
  }

  static Future<void> saveUserData(Map<String, dynamic> user) async {
    await init();
    await _prefs!.setString(AppConstants.userKey, jsonEncode(user));
    if (user['role_name'] != null) {
      await _prefs!.setString(AppConstants.roleKey, user['role_name']);
    }
  }

  static Map<String, dynamic>? getUserData() {
    final str = _prefs?.getString(AppConstants.userKey);
    if (str == null) return null;
    try {
      return jsonDecode(str) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static String? getUserRole() {
    return _prefs?.getString(AppConstants.roleKey);
  }

  static Future<void> saveBaseUrl(String url) async {
    await init();
    await _prefs!.setString(AppConstants.baseUrlKey, url);
  }

  static String getBaseUrl() {
    return _prefs?.getString(AppConstants.baseUrlKey) ?? AppConstants.defaultBaseUrl;
  }

  static Future<void> setDarkMode(bool isDark) async {
    await init();
    await _prefs!.setBool(AppConstants.isDarkModeKey, isDark);
  }

  static bool isDarkMode() {
    return _prefs?.getBool(AppConstants.isDarkModeKey) ?? false;
  }

  static Future<void> clearAuth() async {
    await init();
    await _prefs!.remove(AppConstants.tokenKey);
    await _prefs!.remove(AppConstants.userKey);
    await _prefs!.remove(AppConstants.roleKey);
  }
}
