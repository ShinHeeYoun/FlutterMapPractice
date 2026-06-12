import 'package:flutter/material.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:geolocator/geolocator.dart';

class MapController extends ChangeNotifier {
  KakaoMapController? _kakaoMapController;
  bool _isMapReady = false;

  LatLng? _currentLocation;
  final List<Marker> _markers = [];

  bool get isMapReady => _isMapReady;
  LatLng? get currentLocation => _currentLocation;
  List<Marker> get markers => _markers;

  void onMapCreated(KakaoMapController controller) {
    _kakaoMapController = controller;
    _isMapReady = true;
    notifyListeners();
    
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Location services are disabled.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('Location permissions are denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('Location permissions are permanently denied.');
      return;
    }

    Position position = await Geolocator.getCurrentPosition();
    _currentLocation = LatLng(position.latitude, position.longitude);
    
    _markers.add(
      Marker(
        markerId: 'current_location',
        latLng: _currentLocation!,
      ),
    );

    if (_kakaoMapController != null && _currentLocation != null) {
      _kakaoMapController!.setCenter(_currentLocation!);
    }

    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
