import 'package:flutter/material.dart';
import '../../controller/map_controller.dart';
import '../../controller/alarm_controller.dart';
import 'alarm_setup_bottom_sheet.dart';
import 'settings_bottom_sheet.dart';
import '../alarm_history_screen.dart';

class MenuBottomSheet extends StatelessWidget {
  final MapController mapController;
  final AlarmController alarmController;

  const MenuBottomSheet({
    super.key,
    required this.mapController,
    required this.alarmController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.0),
              ),
            ),
          ),
          const Text(
            '메뉴',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('환경 설정'),
                  onTap: () {
                    Navigator.pop(context);
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => const SettingsBottomSheet(),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.alarm_on, color: Colors.blueAccent),
                  title: const Text('Beta: 목적지 기반 알림 기능 사용'),
                  onTap: () {
                    Navigator.pop(context);
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => AlarmSetupBottomSheet(
                        mapController: mapController,
                        alarmController: alarmController,
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.history, color: Colors.green),
                  title: const Text('목적지 알림 이용 내역 및 통계'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AlarmHistoryScreen(),
                      ),
                    );
                  },
                ),
                // 확장성을 고려하여 향후 여기에 추가 메뉴 아이템 배치 가능
              ],
            ),
          ),
        ],
      ),
    );
  }
}
