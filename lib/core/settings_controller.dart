import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AlarmSoundType {
  defaultSound,
  youtubeLink,
}

class SettingsController extends ChangeNotifier {
  static final SettingsController _instance = SettingsController._internal();
  factory SettingsController() => _instance;
  SettingsController._internal();

  SharedPreferences? _prefs;

  AlarmSoundType _alarmSoundType = AlarmSoundType.defaultSound;
  String _youtubeUrl = '';

  AlarmSoundType get alarmSoundType => _alarmSoundType;
  String get youtubeUrl => _youtubeUrl;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final typeIndex = _prefs?.getInt('alarmSoundType') ?? 0;
    if (typeIndex >= 0 && typeIndex < AlarmSoundType.values.length) {
      _alarmSoundType = AlarmSoundType.values[typeIndex];
    }
    _youtubeUrl = _prefs?.getString('youtubeUrl') ?? '';
    notifyListeners();
  }

  Future<void> setAlarmSoundType(AlarmSoundType type) async {
    _alarmSoundType = type;
    await _prefs?.setInt('alarmSoundType', type.index);
    notifyListeners();
  }

  Future<void> setYoutubeUrl(String url) async {
    _youtubeUrl = url;
    await _prefs?.setString('youtubeUrl', url);
    notifyListeners();
  }
}
