import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

enum LocationStatus {
  initial,
  loading,
  loaded,
  permissionDenied,
  serviceDisabled,
  error,
}

class LocationProvider extends ChangeNotifier {
  Position? _currentPosition;
  LocationStatus _status = LocationStatus.initial;
  String? _errorMessage;
  DateTime? _lastUpdated;

  static const Duration _locationTimeout = Duration(seconds: 10);
  static const Duration _cacheValidity = Duration(minutes: 5);

  Position? get currentPosition => _currentPosition;
  LocationStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get hasLocation => _currentPosition != null;
  bool get isLoading => _status == LocationStatus.loading;

  /// Check if cached location is still valid
  bool get isCacheValid {
    if (_lastUpdated == null || _currentPosition == null) return false;
    return DateTime.now().difference(_lastUpdated!) < _cacheValidity;
  }

  /// Initialize location on app startup
  Future<void> initialize() async {
    await getCurrentLocation();
  }

  /// Get current location with caching
  Future<Position?> getCurrentLocation({bool forceRefresh = false}) async {
    // Return cached position if valid and not forcing refresh
    if (!forceRefresh && isCacheValid) {
      return _currentPosition;
    }

    // Prevent multiple simultaneous requests
    if (_status == LocationStatus.loading) {
      return _currentPosition;
    }

    _status = LocationStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _status = LocationStatus.serviceDisabled;
        _errorMessage = '위치 서비스가 비활성화되어 있습니다.';
        notifyListeners();
        return null;
      }

      // Check permission
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _status = LocationStatus.permissionDenied;
          _errorMessage = '위치 권한이 거부되었습니다.';
          notifyListeners();
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _status = LocationStatus.permissionDenied;
        _errorMessage = '위치 권한이 영구적으로 거부되었습니다. 설정에서 권한을 활성화해주세요.';
        notifyListeners();
        return null;
      }

      // Get current position with timeout
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(
        _locationTimeout,
        onTimeout: () => throw TimeoutException('Location request timed out'),
      );

      _currentPosition = position;
      _lastUpdated = DateTime.now();
      _status = LocationStatus.loaded;
      _errorMessage = null;
      notifyListeners();

      return position;
    } catch (e) {
      debugPrint('Error getting location: $e');
      _status = LocationStatus.error;
      _errorMessage = '위치를 가져오는 중 오류가 발생했습니다.';
      notifyListeners();
      return null;
    }
  }

  /// Calculate distance between current position and a target location
  double? distanceTo(double latitude, double longitude) {
    if (_currentPosition == null) return null;

    return Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      latitude,
      longitude,
    );
  }

  /// Format distance for display
  String? formatDistanceTo(double latitude, double longitude) {
    final distanceMeters = distanceTo(latitude, longitude);
    if (distanceMeters == null) return null;

    final distanceKm = distanceMeters / 1000;
    if (distanceKm < 1) {
      return '${distanceMeters.round()}m';
    }
    return '${distanceKm.toStringAsFixed(1)}km';
  }
}