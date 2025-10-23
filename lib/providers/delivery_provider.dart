import 'package:flutter/foundation.dart';
import '../models/delivery_model.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

/// Delivery Provider - Manages delivery state for drivers
class DeliveryProvider with ChangeNotifier {
  List<Delivery> _deliveries = [];
  Delivery? _activeDelivery;
  bool _isLoading = false;
  String? _error;
  bool _isAvailable = true;

  // Getters
  List<Delivery> get deliveries => _deliveries;
  Delivery? get activeDelivery => _activeDelivery;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAvailable => _isAvailable;

  /// Fetch my deliveries
  Future<void> fetchMyDeliveries() async {
    print('📦 Fetching my deliveries...');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await apiService.get(ApiConfig.myDeliveries);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        _deliveries = data.map((json) => Delivery.fromJson(json)).toList();

        // Find active delivery
        try {
          _activeDelivery = _deliveries.firstWhere(
            (d) => d.isActive,
          );
        } catch (e) {
          _activeDelivery = null;
        }

        print('✅ Fetched ${_deliveries.length} deliveries');
      }
    } catch (e) {
      print('❌ Failed to fetch deliveries: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Accept a delivery
  Future<bool> acceptDelivery(String deliveryId) async {
    print('✅ Accepting delivery: $deliveryId');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final url = ApiConfig.acceptDelivery.replaceAll('{id}', deliveryId);
      final response = await apiService.post(url);

      if (response.statusCode == 200) {
        await fetchMyDeliveries();
        print('✅ Delivery accepted');
        _isLoading = false;
        notifyListeners();
        return true;
      }

      throw Exception('Failed to accept delivery');
    } catch (e) {
      print('❌ Failed to accept delivery: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Mark delivery as picked up
  Future<bool> pickupDelivery(String deliveryId) async {
    print('📍 Marking delivery as picked up: $deliveryId');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await apiService.post(
        '/deliveries/$deliveryId/pickup',
      );

      if (response.statusCode == 200) {
        await fetchMyDeliveries();
        print('✅ Delivery picked up');
        _isLoading = false;
        notifyListeners();
        return true;
      }

      throw Exception('Failed to pickup delivery');
    } catch (e) {
      print('❌ Failed to pickup delivery: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update delivery location (for real-time tracking)
  Future<bool> updateLocation(
    String deliveryId,
    double latitude,
    double longitude,
  ) async {
    try {
      final url = ApiConfig.updateLocation.replaceAll('{id}', deliveryId);
      final response = await apiService.put(
        url,
        data: {
          'latitude': latitude,
          'longitude': longitude,
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Failed to update location: $e');
      return false;
    }
  }

  /// Complete delivery
  Future<bool> completeDelivery(String deliveryId) async {
    print('🎉 Completing delivery: $deliveryId');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final url = ApiConfig.completeDelivery.replaceAll('{id}', deliveryId);
      final response = await apiService.post(url);

      if (response.statusCode == 200) {
        await fetchMyDeliveries();
        _activeDelivery = null;
        print('✅ Delivery completed');
        _isLoading = false;
        notifyListeners();
        return true;
      }

      throw Exception('Failed to complete delivery');
    } catch (e) {
      print('❌ Failed to complete delivery: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Toggle availability status
  Future<void> toggleAvailability() async {
    _isAvailable = !_isAvailable;
    notifyListeners();
    // TODO: Call API to update availability
    print('📡 Availability: ${_isAvailable ? "Available" : "Unavailable"}');
  }

  /// Get delivery statistics
  Map<String, dynamic> get statistics {
    final completed = _deliveries.where((d) => d.status == 'delivered').length;
    final totalEarnings = _deliveries
        .where((d) => d.status == 'delivered')
        .fold<double>(0, (sum, d) => sum + d.earnings);

    return {
      'totalDeliveries': _deliveries.length,
      'completedDeliveries': completed,
      'activeDeliveries': _deliveries.where((d) => d.isActive).length,
      'totalEarnings': totalEarnings,
    };
  }
}
