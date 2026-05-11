import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

class LocationService {
  StreamSubscription<Position>? _positionStreamSubscription;

  Future<bool> handlePermission() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return false;
      }

      if (permission == LocationPermission.deniedForever) return false;

      return true;
    } catch (e) {
      debugPrint('Location permission error: $e');
      return false;
    }
  }

  void startLocationTracking(Function(Position) onLocationChanged) {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Only trigger if moved > 10m
    );

    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) {
        debugPrint('GPS Update: ${position.latitude}, ${position.longitude}');
        onLocationChanged(position);
      },
      onError: (e) {
        debugPrint('Location Stream Error: $e');
      },
    );
  }

  void stopLocationTracking() {
    _positionStreamSubscription?.cancel();
  }

  Future<Position> getCurrentLocation() async {
    return await Geolocator.getCurrentPosition();
  }
}
