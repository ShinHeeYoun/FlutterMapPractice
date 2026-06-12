import 'package:flutter/material.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';

class MapController extends ChangeNotifier {
  KakaoMapController? _kakaoMapController;
  bool _isMapReady = false;

  bool get isMapReady => _isMapReady;

  void onMapCreated(KakaoMapController controller) {
    _kakaoMapController = controller;
    _isMapReady = true;
    notifyListeners();
  }

  @override
  void dispose() {
    // _kakaoMapController doesn't have an explicit dispose method usually, but we clean up if needed
    super.dispose();
  }
}
