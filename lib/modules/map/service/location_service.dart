import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';

class LocationException implements Exception {
  final String message;
  final bool isOutOfBoundary;
  final LatLng? fallbackLocation;

  LocationException(this.message, {this.isOutOfBoundary = false, this.fallbackLocation});

  @override
  String toString() => message;
}

class LocationService {
  // Gangnam Station Fallback
  static final LatLng _seoulFallback = LatLng(37.4979, 127.0276);

  Future<LatLng> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationException(
        'Location services are disabled.',
        isOutOfBoundary: false,
        fallbackLocation: _seoulFallback,
      );
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationException(
          'Location permissions are denied.',
          isOutOfBoundary: false,
          fallbackLocation: _seoulFallback,
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationException(
        'Location permissions are permanently denied.',
        isOutOfBoundary: false,
        fallbackLocation: _seoulFallback,
      );
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Boundary check for South Korea (Lat: 33~39, Lng: 124~132)
      if (position.latitude >= 33 && position.latitude <= 39 &&
          position.longitude >= 124 && position.longitude <= 132) {
        return LatLng(position.latitude, position.longitude);
      } else {
        throw LocationException(
          '국내 위치만 지원하여 서울 중심으로 이동합니다.',
          isOutOfBoundary: true,
          fallbackLocation: _seoulFallback,
        );
      }
    } catch (e) {
      if (e is LocationException) rethrow;
      
      debugPrint('Error getting location: $e');
      throw LocationException(
        'Failed to get current location.',
        isOutOfBoundary: false,
        fallbackLocation: _seoulFallback,
      );
    }
  }
}
