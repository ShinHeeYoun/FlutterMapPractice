import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import '../service/alarm_service.dart';

class AlarmRingingScreen extends StatefulWidget {
  final String distance;

  const AlarmRingingScreen({super.key, required this.distance});

  @override
  State<AlarmRingingScreen> createState() => _AlarmRingingScreenState();
}

class _AlarmRingingScreenState extends State<AlarmRingingScreen> {
  Timer? _vibrateTimer;

  @override
  void initState() {
    super.initState();
    _startAlarm();
  }

  Future<void> _startAlarm() async {
    // Play default alarm ringtone looping
    FlutterRingtonePlayer().playAlarm();
    
    // Vibrate repeatedly
    if (await Vibration.hasVibrator() ?? false) {
      _vibrateTimer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
        Vibration.vibrate(duration: 500);
      });
    }
  }

  void _stopAlarmAndDismiss() {
    FlutterRingtonePlayer().stop();
    _vibrateTimer?.cancel();
    AlarmService.stopAlarm();
    FlutterForegroundTask.stopService();
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    FlutterRingtonePlayer().stop();
    _vibrateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            const Icon(
              Icons.notifications_active,
              color: Colors.white,
              size: 100,
            ),
            const SizedBox(height: 30),
            const Text(
              '목적지 근방입니다!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '남은 거리: 약 ${widget.distance}m',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 20,
              ),
            ),
            const Spacer(),
            // Drag to dismiss
            Dismissible(
              key: const Key('dismiss_alarm'),
              direction: DismissDirection.horizontal,
              onDismissed: (direction) {
                _stopAlarmAndDismiss();
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.close, color: Colors.white),
                    SizedBox(width: 10),
                    Text(
                      '밀어서 알람 끄기',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 10),
                    Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}
