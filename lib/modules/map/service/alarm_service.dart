import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';

import '../../../core/database_helper.dart';
import '../model/alarm_history_model.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(AlarmTaskHandler());
}

class AlarmTaskHandler extends TaskHandler {
  double targetLat = 0;
  double targetLng = 0;
  double radius = 0;
  bool isTriggered = false;

  AlarmHistoryModel? activeHistory;
  LatLng? lastPosition;
  double accumulatedDistance = 0.0;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    final customData = await FlutterForegroundTask.getData<String>(key: 'alarmData');
    if (customData != null) {
      final parts = customData.split(',');
      targetLat = double.parse(parts[0]);
      targetLng = double.parse(parts[1]);
      radius = double.parse(parts[2]);
    }

    // 활성화된 알람 기록 찾기
    activeHistory = await DatabaseHelper.instance.getActiveHistory();
    if (activeHistory != null) {
      accumulatedDistance = activeHistory!.distanceMeters;
      if (activeHistory!.routeCoordinates.isNotEmpty) {
        lastPosition = activeHistory!.routeCoordinates.last;
      }
    }
  }

  @override
  void onRepeatEvent(DateTime timestamp) async {
    if (isTriggered) return;

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final currentLatLng = LatLng(position.latitude, position.longitude);

      // 거리 누적 계산
      if (lastPosition != null) {
        accumulatedDistance += Geolocator.distanceBetween(
          lastPosition!.latitude,
          lastPosition!.longitude,
          currentLatLng.latitude,
          currentLatLng.longitude,
        );
      }
      lastPosition = currentLatLng;

      // DB 업데이트
      if (activeHistory != null) {
        final List<LatLng> updatedCoords = List.from(activeHistory!.routeCoordinates)..add(currentLatLng);
        final int totalTimeSeconds = DateTime.now().difference(activeHistory!.date).inSeconds;
        
        // 평균 속도 (km/h) = (m / 1000) / (s / 3600)
        double avgSpeed = 0.0;
        if (totalTimeSeconds > 0) {
          avgSpeed = (accumulatedDistance / 1000) / (totalTimeSeconds / 3600);
        }

        activeHistory = AlarmHistoryModel(
          id: activeHistory!.id,
          date: activeHistory!.date,
          startName: activeHistory!.startName,
          endName: activeHistory!.endName,
          totalTimeSeconds: totalTimeSeconds,
          distanceMeters: accumulatedDistance,
          averageSpeed: avgSpeed,
          routeCoordinates: updatedCoords,
          status: 'IN_PROGRESS',
        );

        await DatabaseHelper.instance.updateHistory(activeHistory!);
      }

      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        targetLat,
        targetLng,
      );

      FlutterForegroundTask.updateService(
        notificationTitle: '목적지 알림 실행 중',
        notificationText: '남은 거리: ${distance.toStringAsFixed(0)}m',
      );

      if (distance <= radius) {
        isTriggered = true;
        
        if (activeHistory != null) {
          // 알람 트리거 시 COMPLETED 로 변경
          activeHistory = AlarmHistoryModel(
            id: activeHistory!.id,
            date: activeHistory!.date,
            startName: activeHistory!.startName,
            endName: activeHistory!.endName,
            totalTimeSeconds: activeHistory!.totalTimeSeconds,
            distanceMeters: activeHistory!.distanceMeters,
            averageSpeed: activeHistory!.averageSpeed,
            routeCoordinates: activeHistory!.routeCoordinates,
            status: 'COMPLETED',
          );
          await DatabaseHelper.instance.updateHistory(activeHistory!);
        }

        FlutterForegroundTask.wakeUpScreen();
        FlutterForegroundTask.launchApp();
        FlutterForegroundTask.sendDataToMain('ALARM_TRIGGERED_${distance.toStringAsFixed(0)}');
        FlutterForegroundTask.stopService();
      }
    } catch (e) {
      debugPrint('Error in AlarmTaskHandler: $e');
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}

  @override
  void onReceiveData(Object data) {
    if (data is String && data == 'STOP_ALARM') {
      FlutterForegroundTask.stopService();
    }
  }
}

class AlarmService {
  static Future<void> init() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'alarm_service_channel',
        channelName: '목적지 알림 서비스',
        channelDescription: '목적지 도착 알림을 위한 백그라운드 서비스입니다.',
        channelImportance: NotificationChannelImportance.HIGH,
        priority: NotificationPriority.HIGH,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  static Future<bool> requestPermissions() async {
    final NotificationPermission notificationPermissionStatus =
        await FlutterForegroundTask.checkNotificationPermission();
    if (notificationPermissionStatus != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }

    if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    }

    return true;
  }

  static Future<void> startAlarm(double lat, double lng, double radius) async {
    await FlutterForegroundTask.saveData(
      key: 'alarmData',
      value: '$lat,$lng,$radius',
    );
    
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.restartService();
    } else {
      await FlutterForegroundTask.startService(
        notificationTitle: '목적지 알림 시작됨',
        notificationText: '위치 추적 중입니다...',
        callback: startCallback,
      );
    }
  }

  static Future<void> stopAlarm() async {
    if (await FlutterForegroundTask.isRunningService) {
      FlutterForegroundTask.sendDataToTask('STOP_ALARM');
    }
  }
}
