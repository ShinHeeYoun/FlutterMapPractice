import 'package:flutter/material.dart';
import '../model/place_model.dart';
import '../service/alarm_service.dart';

class AlarmController extends ChangeNotifier {
  PlaceModel? _destination;
  double _radius = 500.0; // Default 500m
  bool _isAlarmActive = false;

  PlaceModel? get destination => _destination;
  double get radius => _radius;
  bool get isAlarmActive => _isAlarmActive;

  void setDestination(PlaceModel place) {
    _destination = place;
    notifyListeners();
  }

  void setRadius(double radius) {
    _radius = radius;
    notifyListeners();
  }

  Future<bool> startAlarm() async {
    if (_destination == null) return false;

    bool permissionsGranted = await AlarmService.requestPermissions();
    if (!permissionsGranted) {
      return false;
    }

    await AlarmService.startAlarm(_destination!.lat, _destination!.lng, _radius);
    _isAlarmActive = true;
    notifyListeners();
    return true;
  }

  Future<void> stopAlarm() async {
    await AlarmService.stopAlarm();
    _isAlarmActive = false;
    notifyListeners();
  }
}
