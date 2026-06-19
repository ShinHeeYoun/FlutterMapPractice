import 'dart:convert';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';

class AlarmHistoryModel {
  final int? id;
  final DateTime date;
  final String startName;
  final String endName;
  final int totalTimeSeconds;
  final double distanceMeters;
  final double averageSpeed; // km/h
  final List<LatLng> routeCoordinates;
  final String status; // 'IN_PROGRESS', 'COMPLETED'

  AlarmHistoryModel({
    this.id,
    required this.date,
    required this.startName,
    required this.endName,
    required this.totalTimeSeconds,
    required this.distanceMeters,
    required this.averageSpeed,
    required this.routeCoordinates,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'startName': startName,
      'endName': endName,
      'totalTimeSeconds': totalTimeSeconds,
      'distanceMeters': distanceMeters,
      'averageSpeed': averageSpeed,
      'routeCoordinates': jsonEncode(
          routeCoordinates.map((e) => {'lat': e.latitude, 'lng': e.longitude}).toList()),
      'status': status,
    };
  }

  factory AlarmHistoryModel.fromMap(Map<String, dynamic> map) {
    List<LatLng> coords = [];
    if (map['routeCoordinates'] != null && map['routeCoordinates'] != '') {
      final List<dynamic> decoded = jsonDecode(map['routeCoordinates']);
      coords = decoded.map((e) => LatLng(e['lat'], e['lng'])).toList();
    }

    return AlarmHistoryModel(
      id: map['id'],
      date: DateTime.parse(map['date']),
      startName: map['startName'],
      endName: map['endName'],
      totalTimeSeconds: map['totalTimeSeconds'],
      distanceMeters: map['distanceMeters'],
      averageSpeed: map['averageSpeed'],
      routeCoordinates: coords,
      status: map['status'],
    );
  }
}
