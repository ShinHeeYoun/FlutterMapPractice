import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MapController extends ChangeNotifier {
  KakaoMapController? _kakaoMapController;
  bool _isMapReady = false;
  bool _isLocationInitialized = false;

  LatLng? _currentLocation;
  final List<Marker> _markers = [];

  bool get isMapReady => _isMapReady;
  bool get isLocationInitialized => _isLocationInitialized;
  LatLng? get currentLocation => _currentLocation;
  List<Marker> get markers => _markers;

  MapController() {
    _initializeLocation();
  }

  void onMapCreated(KakaoMapController controller) {
    _kakaoMapController = controller;
    _isMapReady = true;
    notifyListeners();
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

    _isLocationInitialized = true;
    moveToCurrentLocation();
    notifyListeners();
  }

  void moveToCurrentLocation() {
    if (_currentLocation != null && _kakaoMapController != null) {
      _kakaoMapController!.setCenter(_currentLocation!);
    }
  }

  Future<void> searchPlace(String keyword) async {
    if (keyword.isEmpty) return;
    
    final restApiKey = dotenv.env['KAKAO_REST_API_KEY'];
    if (restApiKey == null) {
      debugPrint('REST API KEY is missing');
      return;
    }

    final url = Uri.parse('https://dapi.kakao.com/v2/local/search/keyword.json?query=$keyword');
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'KakaoAK $restApiKey'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final documents = data['documents'] as List;
        
        if (documents.isNotEmpty) {
          final firstPlace = documents.first;
          final lat = double.parse(firstPlace['y']);
          final lng = double.parse(firstPlace['x']);
          final latLng = LatLng(lat, lng);

          // Remove previous search results, keep only current location
          _markers.removeWhere((marker) => marker.markerId != 'current_location');
          
          _markers.add(
            Marker(
              markerId: 'search_result',
              latLng: latLng,
            ),
          );
          
          _kakaoMapController?.setCenter(latLng);
          notifyListeners();
        }
      } else {
        debugPrint('Search API Error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Exception during search: $e');
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
