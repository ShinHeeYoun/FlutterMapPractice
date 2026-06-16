import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'core/settings_controller.dart';
import 'modules/map/view/map_screen.dart';
import 'modules/map/service/alarm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  
  // Initialize Kakao Map Plugin
  AuthRepository.initialize(
    appKey: '400771ec937cf5ee0b60ad77ed472a4e',
    baseUrl: 'http://localhost:8080',
  );

  // Initialize Settings
  await SettingsController().init();

  // Initialize Background Service
  await AlarmService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Map Practice',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // WithForegroundTask is required to handle data from background task easily
      home: const WithForegroundTask(child: MapScreen()),
    );
  }
}
