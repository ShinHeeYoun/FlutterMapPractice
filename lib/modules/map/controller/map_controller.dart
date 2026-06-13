import 'package:flutter/material.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';

import '../model/place_model.dart';
import '../repository/kakao_map_repository.dart';
import '../service/location_service.dart';

class MapController extends ChangeNotifier {
  final LocationService _locationService;
  final KakaoMapRepository _mapRepository;

  KakaoMapController? _kakaoMapController;
  bool _isMapReady = false;
  bool _isLocationInitialized = false;

  LatLng? _currentLocation;
  final List<Marker> _markers = [];
  
  List<PlaceModel> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  
  // Callback for boundary exception
  Function(String message)? onLocationError;

  bool get isMapReady => _isMapReady;
  bool get isLocationInitialized => _isLocationInitialized;
  LatLng? get currentLocation => _currentLocation;
  List<Marker> get markers => _markers;
  List<PlaceModel> get searchResults => _searchResults;
  bool get isSearching => _isSearching;
  bool get hasSearched => _hasSearched;

  // Dependency Injection via constructor
  MapController({
    LocationService? locationService,
    KakaoMapRepository? mapRepository,
    this.onLocationError,
  })  : _locationService = locationService ?? LocationService(),
        _mapRepository = mapRepository ?? KakaoMapRepository() {
    _initializeLocation();
  }

  void onMapCreated(KakaoMapController controller) {
    _kakaoMapController = controller;
    _isMapReady = true;
    notifyListeners();
  }

  Future<void> _initializeLocation() async {
    try {
      final latLng = await _locationService.getCurrentLocation();
      _currentLocation = latLng;
    } on LocationException catch (e) {
      debugPrint('LocationException: ${e.message}');
      // Set fallback location
      _currentLocation = e.fallbackLocation;
      
      // If it's a boundary issue, notify UI
      if (e.isOutOfBoundary && onLocationError != null) {
        onLocationError!(e.message);
      }
    } catch (e) {
      debugPrint('Unknown error in location init: $e');
      _currentLocation = LatLng(37.4979, 127.0276); // Gangnam fallback
    }

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

    _isSearching = true;
    _hasSearched = true;
    notifyListeners();

    try {
      final lat = _currentLocation?.latitude ?? 37.4979;
      final lng = _currentLocation?.longitude ?? 127.0276;
      
      _searchResults = await _mapRepository.searchPlace(
        keyword: keyword,
        lat: lat,
        lng: lng,
      );
    } on RepositoryException catch (e) {
      debugPrint('RepositoryException: ${e.message}');
      _searchResults = [];
    } catch (e) {
      debugPrint('Unknown error during search: $e');
      _searchResults = [];
    }

    _isSearching = false;
    notifyListeners();
  }

  void selectPlace(PlaceModel place) {
    final latLng = LatLng(place.lat, place.lng);

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
