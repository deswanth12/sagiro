import 'package:flutter/material.dart';
import '../services/app_settings_service.dart';

class SettingsProvider extends ChangeNotifier {
  final AppSettingsService _service = AppSettingsService.instance;

  String _themeModeChoice = 'dark';
  bool _darkMode = true;
  bool _amoledMode = false;
  bool _reduceMotion = false;
  bool _hideBalances = false;
  bool _smsTracking = true;
  bool _autoCategories = true;
  bool _biometricsEnabled = false;

  String get themeModeChoice => _themeModeChoice;
  bool get darkMode => _darkMode;
  bool get amoledMode => _amoledMode;
  bool get reduceMotion => _reduceMotion;
  bool get hideBalances => _hideBalances;
  bool get smsTracking => _smsTracking;
  bool get autoCategories => _autoCategories;
  bool get biometricsEnabled => _biometricsEnabled;

  ThemeMode get themeMode {
    switch (_themeModeChoice) {
      case 'light':
        return ThemeMode.light;
      case 'system':
        return ThemeMode.system;
      case 'dark':
      default:
        return ThemeMode.dark;
    }
  }

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await _service.loadSettings();
    _themeModeChoice = _service.themeModeChoice;
    _darkMode = _service.darkMode;
    _amoledMode = _service.amoledMode;
    _reduceMotion = _service.reduceMotion;
    _hideBalances = _service.hideBalances;
    _smsTracking = _service.smsTracking;
    _autoCategories = _service.autoCategories;
    _biometricsEnabled = _service.biometricsEnabled;
    notifyListeners();
  }

  Future<void> setThemeModeChoice(String choice) async {
    _themeModeChoice = choice;
    _darkMode = choice != 'light';
    await _service.setThemeModeChoice(choice);
    notifyListeners();
  }

  Future<void> setDarkMode(bool val) async {
    await setThemeModeChoice(val ? 'dark' : 'light');
  }

  Future<void> setAmoledMode(bool val) async {
    _amoledMode = val;
    await _service.setAmoledMode(val);
    notifyListeners();
  }

  Future<void> setReduceMotion(bool val) async {
    _reduceMotion = val;
    await _service.setReduceMotion(val);
    notifyListeners();
  }

  Future<void> setHideBalances(bool val) async {
    _hideBalances = val;
    await _service.setHideBalances(val);
    notifyListeners();
  }

  Future<void> setSmsTracking(bool val) async {
    _smsTracking = val;
    await _service.setSmsTracking(val);
    notifyListeners();
  }

  Future<void> setAutoCategories(bool val) async {
    _autoCategories = val;
    await _service.setAutoCategories(val);
    notifyListeners();
  }

  Future<void> setBiometricsEnabled(bool val) async {
    _biometricsEnabled = val;
    await _service.setBiometricsEnabled(val);
    notifyListeners();
  }
}
