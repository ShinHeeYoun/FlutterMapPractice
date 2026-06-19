import 'package:flutter/material.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:intl/intl.dart';
import '../model/alarm_history_model.dart';

class AlarmHistoryDetailScreen extends StatefulWidget {
  final AlarmHistoryModel history;

  const AlarmHistoryDetailScreen({super.key, required this.history});

  @override
  State<AlarmHistoryDetailScreen> createState() => _AlarmHistoryDetailScreenState();
}

class _AlarmHistoryDetailScreenState extends State<AlarmHistoryDetailScreen> {
  KakaoMapController? _mapController;
  final List<Marker> _markers = [];
  final List<Polyline> _polylines = [];

  @override
  void initState() {
    super.initState();
    _setupMapData();
  }

  void _setupMapData() {
    if (widget.history.routeCoordinates.isEmpty) return;

    final startPoint = widget.history.routeCoordinates.first;
    final endPoint = widget.history.routeCoordinates.last;

    _markers.add(
      Marker(
        markerId: 'start',
        latLng: startPoint,
        // Using standard markers as KakaoMapPlugin doesn't support custom colors out of the box in simple usage,
        // but we can distinguish by id.
      ),
    );
    _markers.add(
      Marker(
        markerId: 'end',
        latLng: endPoint,
      ),
    );

    _polylines.add(
      Polyline(
        polylineId: 'route',
        points: widget.history.routeCoordinates,
        strokeColor: Colors.blueAccent,
        strokeWidth: 5,
        strokeOpacity: 0.8,
      ),
    );
  }

  void _onMapCreated(KakaoMapController controller) {
    _mapController = controller;
    if (widget.history.routeCoordinates.isNotEmpty) {
      // delay a bit to allow map render
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_mapController != null && mounted) {
           _mapController!.fitBounds(widget.history.routeCoordinates);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(widget.history.date);

    return Scaffold(
      appBar: AppBar(
        title: const Text('상세 이용 내역'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: widget.history.routeCoordinates.isEmpty
                ? const Center(child: Text('기록된 경로 데이터가 없습니다.'))
                : KakaoMap(
                    onMapCreated: _onMapCreated,
                    markers: _markers,
                    polylines: _polylines,
                    center: widget.history.routeCoordinates.first,
                  ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(20.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))
                ],
              ),
              child: ListView(
                children: [
                  Text(dateStr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(child: Text('출발: ${widget.history.startName}', style: const TextStyle(fontSize: 16))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.flag, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(child: Text('도착: ${widget.history.endName}', style: const TextStyle(fontSize: 16))),
                    ],
                  ),
                  const Divider(height: 30, thickness: 1),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatColumn(icon: Icons.timer, title: '소요 시간', value: '${(widget.history.totalTimeSeconds / 60).toStringAsFixed(1)} 분'),
                      _StatColumn(icon: Icons.straighten, title: '이동 거리', value: '${(widget.history.distanceMeters / 1000).toStringAsFixed(2)} km'),
                      _StatColumn(icon: Icons.speed, title: '평균 속도', value: '${widget.history.averageSpeed.toStringAsFixed(1)} km/h'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _StatColumn({required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 28, color: Colors.grey[700]),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
