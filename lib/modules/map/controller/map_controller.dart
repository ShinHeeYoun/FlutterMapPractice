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
  
  List<dynamic> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  
  VoidCallback? onOutOfBoundary;

  bool get isMapReady => _isMapReady;
  bool get isLocationInitialized => _isLocationInitialized;
  LatLng? get currentLocation => _currentLocation;
  List<Marker> get markers => _markers;
  List<dynamic> get searchResults => _searchResults;
  bool get isSearching => _isSearching;
  bool get hasSearched => _hasSearched;

  MapController({this.onOutOfBoundary}) {
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
      _fallbackToSeoul();
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('Location permissions are denied');
        _fallbackToSeoul();
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('Location permissions are permanently denied.');
      _fallbackToSeoul();
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Check if within South Korea bounds (Lat: 33~39, Lng: 124~132)
      if (position.latitude >= 33 && position.latitude <= 39 &&
          position.longitude >= 124 && position.longitude <= 132) {
        _currentLocation = LatLng(position.latitude, position.longitude);
      } else {
        _fallbackToSeoul(triggerCallback: true);
        return;
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      _fallbackToSeoul();
      return;
    }
    
    _finishLocationInitialization();
  }

  void _fallbackToSeoul({bool triggerCallback = false}) {
    // Default to Gangnam Station
    _currentLocation = LatLng(37.4979, 127.0276);
    if (triggerCallback && onOutOfBoundary != null) {
      onOutOfBoundary!();
    }
    _finishLocationInitialization();
  }

  void _finishLocationInitialization() {
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

  void clearSearch() {
    _searchResults.clear();
    _hasSearched = false;
    notifyListeners();
  }

  Future<void> searchPlace(String keyword) async {
    if (keyword.isEmpty) {
      clearSearch();
      return;
    }
    
    final restApiKey = dotenv.env['KAKAO_REST_API_KEY'];
    if (restApiKey == null) {
      debugPrint('REST API KEY is missing');
      return;
    }

    _isSearching = true;
    _hasSearched = true;
    notifyListeners();

    // Include x, y for distance sort
    final x = _currentLocation?.longitude ?? 127.0276;
    final y = _currentLocation?.latitude ?? 37.4979;
    final url = Uri.parse('https://dapi.kakao.com/v2/local/search/keyword.json?query=$keyword&x=$x&y=$y&sort=distance');
    
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'KakaoAK $restApiKey'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _searchResults = data['documents'] as List;
      } else {
        debugPrint('Search API Error: ${response.statusCode}');
        _searchResults = [];
      }
    } catch (e) {
      debugPrint('Exception during search: $e');
      _searchResults = [];
    }

    _isSearching = false;
    notifyListeners();
  }

  void selectPlace(dynamic place) {
    final lat = double.parse(place['y']);
    final lng = double.parse(place['x']);
    final latLng = LatLng(lat, lng);

    _markers.removeWhere((marker) => marker.markerId != 'current_location');
    _markers.add(
      Marker(
        markerId: 'search_result',
        latLng: latLng,
      ),
    );
    
    _kakaoMapController?.setCenter(latLng);
    clearSearch();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
