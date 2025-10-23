import 'package:location/location.dart' as loc;
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math' show cos, sqrt, asin;

/// Location Service - Handles location permissions and fetching
class LocationService {
  final loc.Location _location = loc.Location();

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await _location.serviceEnabled();
  }

  /// Request to enable location services
  Future<bool> requestService() async {
    return await _location.requestService();
  }

  /// Check location permission status
  Future<loc.PermissionStatus> checkPermission() async {
    return await _location.hasPermission();
  }

  /// Request location permission
  Future<loc.PermissionStatus> requestPermission() async {
    return await _location.requestPermission();
  }

  /// Get current location with permission check
  Future<loc.LocationData?> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('⚠️ Location services are disabled. Requesting...');
        serviceEnabled = await requestService();
        if (!serviceEnabled) {
          print('⚠️ Location services still disabled');
          return null;
        }
      }

      // Check permission
      loc.PermissionStatus permission = await checkPermission();

      if (permission == loc.PermissionStatus.denied) {
        permission = await requestPermission();
        if (permission != loc.PermissionStatus.granted) {
          print('⚠️ Location permission denied');
          return null;
        }
      }

      if (permission == loc.PermissionStatus.deniedForever) {
        print('⚠️ Location permission denied forever');
        return null;
      }

      // Get current position
      final locationData = await _location.getLocation();

      print('✅ Current location: ${locationData.latitude}, ${locationData.longitude}');
      return locationData;
    } catch (e) {
      print('❌ Error getting location: $e');
      return null;
    }
  }

  /// Get address from coordinates (reverse geocoding)
  Future<String?> getAddressFromCoordinates(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final address = [
          place.street,
          place.locality,
          place.administrativeArea,
          place.country,
        ].where((e) => e != null && e.isNotEmpty).join(', ');

        print('✅ Address: $address');
        return address;
      }
      return null;
    } catch (e) {
      print('❌ Error getting address: $e');
      return null;
    }
  }

  /// Get coordinates from address (geocoding)
  Future<LatLng?> getCoordinatesFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);

      if (locations.isNotEmpty) {
        final location = locations.first;
        return LatLng(location.latitude, location.longitude);
      }
      return null;
    } catch (e) {
      print('❌ Error geocoding address: $e');
      return null;
    }
  }

  /// Calculate distance between two coordinates (in meters) using Haversine formula
  double calculateDistance(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    const double earthRadius = 6371000; // meters

    final double dLat = _toRadians(endLat - startLat);
    final double dLng = _toRadians(endLng - startLng);

    final double a = (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_toRadians(startLat)) *
            cos(_toRadians(endLat)) *
            (sin(dLng / 2) * sin(dLng / 2));

    final double c = 2 * asin(sqrt(a));

    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * 3.141592653589793 / 180;
  }

  double sin(double radians) {
    return radians - (radians * radians * radians) / 6;
  }
}

final locationService = LocationService();
