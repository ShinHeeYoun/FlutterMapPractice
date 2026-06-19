import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import '../../../core/database_helper.dart';
import '../model/alarm_history_model.dart';
import '../model/place_model.dart';
import '../repository/kakao_map_repository.dart';
import '../service/alarm_service.dart';
class AlarmController extends ChangeNotifier {
  PlaceModel? _destination;
  double _radius = 500.0; // Default 500m
  bool _isAlarmActive = false;

  StreamSubscription<Position>? _positionStream;
  double _remainingDistance = 0.0;
  List<LatLng> _trackingRoute = [];

  PlaceModel? get destination => _destination;
  double get radius => _radius;
  bool get isAlarmActive => _isAlarmActive;
  double get remainingDistance => _remainingDistance;
  List<LatLng> get trackingRoute => _trackingRoute;

  void setDestination(PlaceModel place) {
    _destination = place;
    notifyListeners();
  }

  void setRadius(double radius) {
    _radius = radius;
    notifyListeners();
  }

  Future<bool> startAlarm({required String startName}) async {
    if (_destination == null) return false;

    bool permissionsGranted = await AlarmService.requestPermissions();
    if (!permissionsGranted) {
      return false;
    }

    // 새 히스토리 생성
    final newHistory = AlarmHistoryModel(
      date: DateTime.now(),
      startName: startName,
      endName: _destination!.placeName,
      totalTimeSeconds: 0,
      distanceMeters: 0,
      averageSpeed: 0,
      routeCoordinates: [],
      status: 'IN_PROGRESS',
    );
    await DatabaseHelper.instance.insertHistory(newHistory);

    await AlarmService.startAlarm(_destination!.lat, _destination!.lng, _radius);
    _isAlarmActive = true;
    _trackingRoute.clear();
    
    // 포그라운드에서 실시간 거리 계산 및 궤적 기록
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 2,
      ),
    ).listen((position) {
      if (_destination != null) {
        _remainingDistance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          _destination!.lat,
          _destination!.lng,
        );
      }
      _trackingRoute.add(LatLng(position.latitude, position.longitude));
      notifyListeners();
    });

    notifyListeners();
    return true;
  }

  Future<void> stopAlarm() async {
    await AlarmService.stopAlarm();
    _positionStream?.cancel();
    _isAlarmActive = false;
    _trackingRoute.clear();
    
    // 강제 종료 시 IN_PROGRESS 상태인 기록을 찾아 최종 위치로 업데이트 및 COMPLETED로 변경
    final activeHistory = await DatabaseHelper.instance.getActiveHistory();
    if (activeHistory != null) {
      String finalEndName = activeHistory.endName; // 기본값은 원래 목적지

      if (activeHistory.routeCoordinates.isNotEmpty) {
        final lastPos = activeHistory.routeCoordinates.last;
        final kakaoRepo = KakaoMapRepository();
        final address = await kakaoRepo.coordToAddress(lat: lastPos.latitude, lng: lastPos.longitude);
        if (address != '알 수 없음') {
          finalEndName = '중도 종료 ($address)';
        } else {
          finalEndName = '중도 종료';
        }
      }

      final completedHistory = AlarmHistoryModel(
        id: activeHistory.id,
        date: activeHistory.date,
        startName: activeHistory.startName,
        endName: finalEndName,
        totalTimeSeconds: activeHistory.totalTimeSeconds,
        distanceMeters: activeHistory.distanceMeters,
        averageSpeed: activeHistory.averageSpeed,
        routeCoordinates: activeHistory.routeCoordinates,
        status: 'COMPLETED',
      );
      await DatabaseHelper.instance.updateHistory(completedHistory);
    }
    
    notifyListeners();
  }
}
