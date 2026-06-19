import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';

import '../model/place_model.dart';
import '../repository/kakao_map_repository.dart';
import '../service/location_service.dart';

class MapController extends ChangeNotifier {
  final LocationService _locationService;
  final KakaoMapRepository _mapRepository;

  KakaoMapController? _kakaoMapController;
  bool _isMapReady = false;
  bool _isLocationInitialized = false;
  Timer? _routeAnimationTimer;

  LatLng? _currentLocation;
  final List<Marker> _markers = [];
  
  List<PlaceModel> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;

  bool _isTrackingMode = false;
  double _heading = 0.0;
  StreamSubscription? _locationSubscription;
  StreamSubscription<CompassEvent>? _compassSubscription;
  
  // Callback for boundary exception
  Function(String message)? onLocationError;

  KakaoMapController? get kakaoMapController => _kakaoMapController;
  bool get isMapReady => _isMapReady;
  bool get isLocationInitialized => _isLocationInitialized;
  LatLng? get currentLocation => _currentLocation;
  List<Marker> get markers => _markers;
  List<PlaceModel> get searchResults => _searchResults;
  bool get isSearching => _isSearching;
  bool get hasSearched => _hasSearched;
  bool get isTrackingMode => _isTrackingMode;
  double get heading => _heading;

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

  void toggleTrackingMode() {
    if (_isTrackingMode) {
      disableTrackingMode();
    } else {
      _enableTrackingMode();
    }
  }

  void _enableTrackingMode() {
    _isTrackingMode = true;
    moveToCurrentLocation();

    // Start location tracking
    _locationSubscription ??= _locationService.getLocationStream().listen((position) {
      final latLng = LatLng(position.latitude, position.longitude);
      _currentLocation = latLng;
      
      // Update marker
      _markers.removeWhere((marker) => marker.markerId == 'current_location');
      _markers.add(
        Marker(
          markerId: 'current_location',
          latLng: latLng,
        ),
      );

      if (_isTrackingMode && _kakaoMapController != null) {
        _kakaoMapController!.setCenter(latLng);
      }
      notifyListeners();
    });

    // Start compass tracking
    _compassSubscription ??= _locationService.getCompassStream()?.listen((event) {
      if (event.heading != null) {
        _heading = event.heading!;
        if (_isTrackingMode) {
          notifyListeners();
        }
      }
    });

    notifyListeners();
  }

  void disableTrackingMode() {
    if (_isTrackingMode) {
      _isTrackingMode = false;
      notifyListeners();
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

  Future<List<PlaceModel>> fetchPlaces(String keyword) async {
    try {
      final lat = _currentLocation?.latitude ?? 37.4979;
      final lng = _currentLocation?.longitude ?? 127.0276;
      
      return await _mapRepository.searchPlace(
        keyword: keyword,
        lat: lat,
        lng: lng,
      );
    } catch (e) {
      debugPrint('Error fetching places: $e');
      return [];
    }
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
    
    disableTrackingMode();
    _kakaoMapController?.setCenter(latLng);
    clearSearch();
  }

  void fitBoundsToPoints(LatLng current, LatLng destination) {
    if (_kakaoMapController == null) return;
    _kakaoMapController!.fitBounds([current, destination]);
  }

  void clearRoute() {
    _routeAnimationTimer?.cancel();
    _kakaoMapController?.clearPolyline(); // This might clear all polylines, which is fine since we only have the route polylines.
  }

  void drawAnimatedRoute(LatLng current, LatLng destination) {
    clearRoute();
    if (_kakaoMapController == null) return;

    // Draw background pipe
    final backgroundPolyline = Polyline(
      polylineId: 'route_background',
      points: [current, destination],
      strokeColor: Colors.grey,
      strokeOpacity: 0.5,
      strokeWidth: 6,
      strokeStyle: StrokeStyle.solid,
    );
    _kakaoMapController!.addPolyline(polylines: [backgroundPolyline]);

    // Animate foreground water
    const int steps = 50;
    int currentStep = 0;
    
    _routeAnimationTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      currentStep++;
      if (currentStep > steps) {
        timer.cancel();
        return;
      }

      final double lat = current.latitude + (destination.latitude - current.latitude) * (currentStep / steps);
      final double lng = current.longitude + (destination.longitude - current.longitude) * (currentStep / steps);
      
      final animatedPolyline = Polyline(
        polylineId: 'route_foreground',
        points: [current, LatLng(lat, lng)],
        strokeColor: Colors.blueAccent,
        strokeOpacity: 0.8,
        strokeWidth: 6,
        strokeStyle: StrokeStyle.solid,
      );
      
      _kakaoMapController!.addPolyline(polylines: [animatedPolyline]);
    });
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _compassSubscription?.cancel();
    super.dispose();
  }
}
