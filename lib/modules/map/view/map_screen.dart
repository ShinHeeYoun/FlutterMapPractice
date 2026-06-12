import 'package:flutter/material.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import '../controller/map_controller.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kakao Map Practice'),
      ),
      body: AnimatedBuilder(
        animation: _mapController,
        builder: (context, child) {
          return KakaoMap(
            onMapCreated: (controller) {
              _mapController.onMapCreated(controller);
            },
            markers: _mapController.markers.toList(),
          );
        },
      ),
    );
  }
}
