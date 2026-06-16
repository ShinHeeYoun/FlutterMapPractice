import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(AlarmTaskHandler());
}

class AlarmTaskHandler extends TaskHandler {
  SendPort? _sendPort;
  double targetLat = 0;
  double targetLng = 0;
  double radius = 0;
  bool isTriggered = false;

  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    _sendPort = sendPort;
    final customData = await FlutterForegroundTask.getData<String>(key: 'alarmData');
    if (customData != null) {
      final parts = customData.split(',');
      targetLat = double.parse(parts[0]);
      targetLng = double.parse(parts[1]);
      radius = double.parse(parts[2]);
    }
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp, SendPort? sendPort) async {
    if (isTriggered) return;

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
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
        // Wake up screen and launch app to foreground
        FlutterForegroundTask.wakeUpScreen();
        FlutterForegroundTask.launchApp();
        
        // Notify main thread
        sendPort?.send('ALARM_TRIGGERED_${distance.toStringAsFixed(0)}');
        
        // Stop service after trigger
        FlutterForegroundTask.stopService();
      }
    } catch (e) {
      debugPrint('Error in AlarmTaskHandler: $e');
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {}

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
        iconData: const NotificationIconData(
          resType: ResourceType.mipmap,
          resPrefix: ResourcePrefix.ic,
          name: 'launcher',
        ),
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: const ForegroundTaskOptions(
        interval: 5000,
        isOnceEvent: false,
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
      await FlutterForegroundTask.stopService();
    }
  }
}
