import 'package:flutter/material.dart';
import '../models/app_settings.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';

class SettingsProvider extends ChangeNotifier {
  final StorageService _storage;
  SettingsProvider(this._storage);

  AppSettings _settings = AppSettings();
  AppSettings get settings => _settings;
  bool _loaded = false;
  bool get loaded => _loaded;

  Future<void> load() async {
    _settings = await _storage.loadSettings();
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    await _storage.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _settings.themeMode = mode;
    await _persist();
  }

  Future<void> setFontScale(FontScale scale) async {
    _settings.fontScale = scale;
    await _persist();
  }

  Future<void> setNotifyOneMonthBefore(bool value) async {
    _settings.notifyOneMonthBefore = value;
    await _persist();
  }

  Future<void> setNotifyLastWeek(bool value) async {
    _settings.notifyLastWeek = value;
    await _persist();
  }

  Future<void> setNotifyDailySummary(bool value) async {
    _settings.notifyDailySummary = value;
    await NotificationService.instance.setDailySummary(value);
    await _persist();
  }

  Future<void> setBiometricLock(bool value) async {
    _settings.biometricLock = value;
    await _persist();
  }

  Future<void> setCloudBackupEnabled(bool value) async {
    _settings.cloudBackupEnabled = value;
    await _persist();
  }

  Future<void> updateProfile({String? name, String? email}) async {
    if (name != null) _settings.userName = name;
    if (email != null) _settings.userEmail = email;
    await _persist();
  }
}
