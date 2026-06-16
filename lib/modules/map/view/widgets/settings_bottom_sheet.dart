import 'package:flutter/material.dart';
import '../../../../core/settings_controller.dart';

class SettingsBottomSheet extends StatefulWidget {
  const SettingsBottomSheet({super.key});

  @override
  State<SettingsBottomSheet> createState() => _SettingsBottomSheetState();
}

class _SettingsBottomSheetState extends State<SettingsBottomSheet> {
  final SettingsController _settingsController = SettingsController();
  final TextEditingController _youtubeUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _youtubeUrlController.text = _settingsController.youtubeUrl;
  }

  @override
  void dispose() {
    _youtubeUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _settingsController,
      builder: (context, child) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
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
                '환경 설정',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              const Text(
                '알림음 선택',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              RadioListTile<AlarmSoundType>(
                title: const Text('기본 알림음'),
                value: AlarmSoundType.defaultSound,
                groupValue: _settingsController.alarmSoundType,
                onChanged: (value) {
                  if (value != null) {
                    _settingsController.setAlarmSoundType(value);
                  }
                },
              ),
              RadioListTile<AlarmSoundType>(
                title: const Text('Youtube 링크'),
                value: AlarmSoundType.youtubeLink,
                groupValue: _settingsController.alarmSoundType,
                onChanged: (value) {
                  if (value != null) {
                    _settingsController.setAlarmSoundType(value);
                  }
                },
              ),
              if (_settingsController.alarmSoundType == AlarmSoundType.youtubeLink) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _youtubeUrlController,
                  decoration: InputDecoration(
                    labelText: '유튜브 링크 입력',
                    hintText: 'https://www.youtube.com/watch?v=...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) {
                    _settingsController.setYoutubeUrl(value);
                  },
                ),
                const SizedBox(height: 8),
                const Text(
                  '알림이 울릴 때 해당 유튜브 영상의 오디오를 재생합니다.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
