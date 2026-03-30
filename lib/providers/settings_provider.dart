import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/settings.dart';

class SettingsProvider extends ChangeNotifier {
  AppSettings _settings = AppSettings();
  AppSettings get settings => _settings;

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _settings = AppSettings(
      totalRequiredHours: prefs.getDouble('totalRequiredHours') ?? 500.0,
      allowancePerDay: prefs.getDouble('allowancePerDay') ?? 0.0,
      employeeName: prefs.getString('employeeName') ?? '',
      supervisorName: prefs.getString('supervisorName') ?? '',
    );
    notifyListeners();
  }

  Future<void> updateSettings(AppSettings newSettings) async {
    _settings = newSettings;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('totalRequiredHours', newSettings.totalRequiredHours);
    await prefs.setDouble('allowancePerDay', newSettings.allowancePerDay);
    await prefs.setString('employeeName', newSettings.employeeName);
    await prefs.setString('supervisorName', newSettings.supervisorName);
    notifyListeners();
  }
}