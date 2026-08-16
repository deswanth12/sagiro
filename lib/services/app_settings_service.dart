import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_helper.dart';

class AppSettingsService {
  static final AppSettingsService instance = AppSettingsService._();
  AppSettingsService._();

  static const String keyDarkMode = 'setting_dark_mode';
  static const String keyAmoledMode = 'setting_amoled_mode';
  static const String keyReduceMotion = 'setting_reduce_motion';
  static const String keySmsTracking = 'setting_sms_tracking';
  static const String keyAutoCategories = 'setting_auto_categories';
  static const String keyBiometricsEnabled = 'setting_biometrics_enabled';
  static const String keyHideBalances = 'setting_hide_balances';
  static const String keyLastImportTimestamp = 'setting_last_import_timestamp';
  static const String keyLastBackupTimestamp = 'setting_last_backup_timestamp';
  static const String keyOnboardingCompleted = 'setting_onboarding_completed';

  static const String keySalaryArrivalDay = 'setting_salary_arrival_day';
  static const String keyThemeModeChoice = 'setting_theme_mode_choice';
  static const String keyMonthCycleStartDay = 'setting_month_cycle_start_day';
  static const String keyDefaultCurrency = 'setting_default_currency';
  static const String keyAppLanguage = 'setting_app_language';
  static const String keyAppRegion = 'setting_app_region';
  static const String keyCoachTone = 'setting_coach_tone';

  String _themeModeChoice = 'dark'; // 'light', 'dark', 'system'
  bool _darkMode = true;
  bool _amoledMode = false;
  bool _reduceMotion = false;
  bool _smsTracking = true;
  bool _autoCategories = true;
  bool _biometricsEnabled = false;
  bool _hideBalances = false;
  bool _onboardingCompleted = false;
  DateTime? _lastImportTimestamp;
  DateTime? _lastBackupTimestamp;
  int _salaryArrivalDay = 28;
  int _monthCycleStartDay = 1;
  String _defaultCurrency = 'INR (₹)';
  String _appLanguage = 'English';
  String _appRegion = 'India 🇮🇳 (INR ₹)';
  String _coachTone = 'Encouraging';

  String get themeModeChoice => _themeModeChoice;
  bool get darkMode => _themeModeChoice == 'dark' || (_themeModeChoice == 'system' ? _darkMode : false);
  bool get amoledMode => _amoledMode;
  bool get reduceMotion => _reduceMotion;
  bool get smsTracking => _smsTracking;
  bool get autoCategories => _autoCategories;
  bool get biometricsEnabled => _biometricsEnabled;
  bool get hideBalances => _hideBalances;
  bool get hasCompletedOnboarding => _onboardingCompleted;
  DateTime? get lastImportTimestamp => _lastImportTimestamp;
  DateTime? get lastBackupTimestamp => _lastBackupTimestamp;
  int get salaryArrivalDay => _salaryArrivalDay;
  int get monthCycleStartDay => _monthCycleStartDay;
  String get defaultCurrency => _defaultCurrency;
  String get appLanguage => _appLanguage;
  String get appRegion => _appRegion;
  String get coachTone => _coachTone;

  Future<void> setOnboardingCompleted(bool value) async {
    _onboardingCompleted = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(keyOnboardingCompleted, value);
    } catch (_) {}
  }

  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _darkMode = prefs.getBool(keyDarkMode) ?? true;
      _themeModeChoice = prefs.getString(keyThemeModeChoice) ?? (_darkMode ? 'dark' : 'light');
      _amoledMode = prefs.getBool(keyAmoledMode) ?? false;
      _reduceMotion = prefs.getBool(keyReduceMotion) ?? false;
      _smsTracking = prefs.getBool(keySmsTracking) ?? true;
      _autoCategories = prefs.getBool(keyAutoCategories) ?? true;
      _biometricsEnabled = prefs.getBool(keyBiometricsEnabled) ?? false;
      _hideBalances = prefs.getBool(keyHideBalances) ?? false;
      _onboardingCompleted = prefs.getBool(keyOnboardingCompleted) ?? false;
      _salaryArrivalDay = prefs.getInt(keySalaryArrivalDay) ?? 28;
      _monthCycleStartDay = prefs.getInt(keyMonthCycleStartDay) ?? 1;
      _defaultCurrency = prefs.getString(keyDefaultCurrency) ?? 'INR (₹)';
      _appLanguage = prefs.getString(keyAppLanguage) ?? 'English';
      _appRegion = prefs.getString(keyAppRegion) ?? 'India 🇮🇳 (INR ₹)';
      _coachTone = prefs.getString(keyCoachTone) ?? 'Encouraging';

      final lastImportStr = prefs.getString(keyLastImportTimestamp);
      if (lastImportStr != null && lastImportStr.isNotEmpty) {
        _lastImportTimestamp = DateTime.tryParse(lastImportStr);
      }

      final lastBackupStr = prefs.getString(keyLastBackupTimestamp);
      if (lastBackupStr != null && lastBackupStr.isNotEmpty) {
        _lastBackupTimestamp = DateTime.tryParse(lastBackupStr);
      }
    } catch (e) {
      debugPrint('AppSettingsService load error: $e');
    }
  }

  Future<void> updateLastBackupTimestamp(DateTime date) async {
    _lastBackupTimestamp = date;
    final iso = date.toIso8601String();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(keyLastBackupTimestamp, iso);
      await DatabaseHelper.instance.setSetting(keyLastBackupTimestamp, iso);
    } catch (_) {}
  }

  Future<void> setThemeModeChoice(String choice) async {
    _themeModeChoice = choice;
    _darkMode = choice != 'light';
    await _saveString(keyThemeModeChoice, choice);
    await _saveBool(keyDarkMode, _darkMode);
  }

  Future<void> setDarkMode(bool value) async {
    await setThemeModeChoice(value ? 'dark' : 'light');
  }

  Future<void> setAmoledMode(bool value) async {
    _amoledMode = value;
    await _saveBool(keyAmoledMode, value);
  }

  Future<void> setReduceMotion(bool value) async {
    _reduceMotion = value;
    await _saveBool(keyReduceMotion, value);
  }

  Future<void> setSmsTracking(bool value) async {
    _smsTracking = value;
    await _saveBool(keySmsTracking, value);
  }

  Future<void> setAutoCategories(bool value) async {
    _autoCategories = value;
    await _saveBool(keyAutoCategories, value);
  }

  Future<void> setBiometricsEnabled(bool value) async {
    _biometricsEnabled = value;
    await _saveBool(keyBiometricsEnabled, value);
  }

  Future<void> setHideBalances(bool value) async {
    _hideBalances = value;
    await _saveBool(keyHideBalances, value);
  }

  Future<void> setSalaryArrivalDay(int value) async {
    _salaryArrivalDay = value;
    await _saveInt(keySalaryArrivalDay, value);
  }

  Future<void> setMonthCycleStartDay(int value) async {
    _monthCycleStartDay = value;
    await _saveInt(keyMonthCycleStartDay, value);
  }

  Future<void> setDefaultCurrency(String value) async {
    _defaultCurrency = value;
    await _saveString(keyDefaultCurrency, value);
  }

  Future<void> setAppLanguage(String value) async {
    _appLanguage = value;
    await _saveString(keyAppLanguage, value);
  }

  Future<void> setAppRegion(String value) async {
    _appRegion = value;
    await _saveString(keyAppRegion, value);
  }

  Future<void> setCoachTone(String value) async {
    _coachTone = value;
    await _saveString(keyCoachTone, value);
  }

  Future<void> updateLastImportTimestamp(DateTime date) async {
    _lastImportTimestamp = date;
    final iso = date.toIso8601String();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(keyLastImportTimestamp, iso);
      await DatabaseHelper.instance.setSetting(keyLastImportTimestamp, iso);
    } catch (e) {
      debugPrint('AppSettingsService updateLastImportTimestamp error: $e');
    }
  }

  Future<void> _saveBool(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
      await DatabaseHelper.instance.setSetting(key, value ? 'true' : 'false');
    } catch (e) {
      debugPrint('AppSettingsService saveBool error for $key: $e');
    }
  }

  Future<void> _saveInt(String key, int value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(key, value);
      await DatabaseHelper.instance.setSetting(key, value.toString());
    } catch (e) {
      debugPrint('AppSettingsService saveInt error for $key: $e');
    }
  }

  Future<void> _saveString(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
      await DatabaseHelper.instance.setSetting(key, value);
    } catch (e) {
      debugPrint('AppSettingsService saveString error for $key: $e');
    }
  }
}
