import 'dart:async';
import 'dart:math';
import 'package:location/location.dart' as loc;
import 'location_service.dart';
import 'websocket_service.dart';
import 'notification_service.dart';
import '../providers/delivery_provider.dart';
import '../models/delivery_model.dart';

/// Real-Time Delivery Tracking Service
/// Automatically updates driver location and sends to backend via WebSocket
class RealtimeDeliveryService {
  static final RealtimeDeliveryService _instance = RealtimeDeliveryService._internal();
  factory RealtimeDeliveryService() => _instance;
  RealtimeDeliveryService._internal();

  Timer? _locationTimer;
  StreamSubscription<loc.LocationData>? _locationSubscription;
  bool _isTracking = false;
  String? _currentDeliveryId;
  String? _currentOrderId;
  String? _currentTrackingNumber;
  String? _lastNotifiedStatus;
  bool _hasNotifiedNearby = false;
  DeliveryProvider? _deliveryProvider;

  /// Check if tracking is active
  bool get isTracking => _isTracking;

  /// Initialize with delivery provider
  void init(DeliveryProvider provider) {
    _deliveryProvider = provider;
  }

  /// Start real-time location tracking for active delivery
  Future<void> startTracking(String deliveryId, {String? orderId, String? trackingNumber}) async {
    if (_isTracking) {
      print('⚠️ Already tracking delivery: $_currentDeliveryId');
      return;
    }

    print('🚀 Starting real-time tracking for delivery: $deliveryId');
    _currentDeliveryId = deliveryId;
    _currentOrderId = orderId;
    _currentTrackingNumber = trackingNumber;
    _lastNotifiedStatus = null;
    _hasNotifiedNearby = false;
    _isTracking = true;

    // Connect to WebSocket if not already connected
    if (!websocketService.isConnected) {
      await websocketService.connect();
    }

    // Listen for WebSocket updates and trigger notifications
    _setupNotificationListeners();

    // Start location updates
    await _startLocationUpdates();
  }

  /// Stop real-time location tracking
  void stopTracking() {
    if (!_isTracking) {
      return;
    }

    print('🛑 Stopping real-time tracking');
    _isTracking = false;
    _currentDeliveryId = null;

    // Cancel timers and subscriptions
    _locationTimer?.cancel();
    _locationTimer = null;

    _locationSubscription?.cancel();
    _locationSubscription = null;
  }

  /// Start sending location updates
  Future<void> _startLocationUpdates() async {
    try {
      // Try to use continuous location updates first (more accurate)
      final location = loc.Location();

      // Check if we can use background location
      bool backgroundModeEnabled = await location.enableBackgroundMode(enable: true);
      print('📍 Background location: ${backgroundModeEnabled ? "enabled" : "disabled"}');

      // Listen to location changes
      _locationSubscription = location.onLocationChanged.listen((locationData) {
        if (_isTracking && _currentDeliveryId != null) {
          _sendLocationUpdate(
            locationData.latitude!,
            locationData.longitude!,
          );
        }
      });

      // Fallback: Use timer-based updates (every 10 seconds)
      _locationTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
        if (!_isTracking || _currentDeliveryId == null) {
          timer.cancel();
          return;
        }

        final locationData = await locationService.getCurrentLocation();
        if (locationData != null && locationData.latitude != null && locationData.longitude != null) {
          _sendLocationUpdate(
            locationData.latitude!,
            locationData.longitude!,
          );
        }
      });

      print('✅ Location updates started');
    } catch (e) {
      print('❌ Error starting location updates: $e');
    }
  }

  /// Send location update to backend
  void _sendLocationUpdate(double latitude, double longitude) {
    if (_currentDeliveryId == null) return;

    print('📍 Sending location: $latitude, $longitude');

    // Send via WebSocket for real-time updates
    websocketService.updateDriverLocation(latitude, longitude);

    // Also send via REST API to persist in database
    _deliveryProvider?.updateLocation(
      _currentDeliveryId!,
      latitude,
      longitude,
    );
  }

  /// Setup notification listeners for WebSocket events
  void _setupNotificationListeners() {
    // Listen for delivery location updates (driver moving)
    websocketService.onDeliveryLocationUpdate((data) {
      _handleDriverLocationUpdate(data);
    });

    // Listen for order status changes
    websocketService.onOrderStatusChange((data) {
      _handleOrderStatusChange(data);
    });
  }

  /// Handle driver location update and check proximity
  void _handleDriverLocationUpdate(dynamic data) {
    try {
      if (data == null || !_isTracking) return;

      final driverLat = data['latitude'] as double?;
      final driverLng = data['longitude'] as double?;
      final deliveryLat = data['deliveryLatitude'] as double?;
      final deliveryLng = data['deliveryLongitude'] as double?;
      final driverName = data['driverName'] as String?;

      if (driverLat != null && driverLng != null &&
          deliveryLat != null && deliveryLng != null &&
          !_hasNotifiedNearby) {

        // Calculate distance between driver and delivery location
        final distance = _calculateDistance(
          driverLat, driverLng,
          deliveryLat, deliveryLng,
        );

        // Notify when driver is within 1km
        if (distance <= 1.0 && _currentOrderId != null && _currentTrackingNumber != null) {
          _hasNotifiedNearby = true;
          final estimatedMinutes = (distance * 2).ceil(); // Rough estimate: 2 min per km

          notificationService.showDriverNearbyNotification(
            orderId: _currentOrderId!,
            trackingNumber: _currentTrackingNumber!,
            driverName: driverName ?? 'Your driver',
            estimatedMinutes: estimatedMinutes > 0 ? '$estimatedMinutes min' : 'less than 1 min',
          );

          print('🔔 Driver nearby notification sent (${distance.toStringAsFixed(2)}km away)');
        }
      }
    } catch (e) {
      print('❌ Error handling driver location update: $e');
    }
  }

  /// Handle order status change and send notification
  void _handleOrderStatusChange(dynamic data) {
    try {
      if (data == null || !_isTracking) return;

      final status = data['status'] as String?;
      final orderId = data['orderId'] as String? ?? _currentOrderId;
      final trackingNumber = data['trackingNumber'] as String? ?? _currentTrackingNumber;
      final driverName = data['driverName'] as String?;
      final estimatedTime = data['estimatedTime'] as String?;

      if (status != null && status != _lastNotifiedStatus &&
          orderId != null && trackingNumber != null) {

        _lastNotifiedStatus = status;

        // Send notification based on status
        notificationService.showOrderNotification(
          orderId: orderId,
          trackingNumber: trackingNumber,
          status: status,
          driverName: driverName,
          estimatedTime: estimatedTime,
        );

        print('🔔 Order status notification sent: $status');

        // Reset nearby notification flag on certain status changes
        if (status.toLowerCase() == 'picked_up' ||
            status.toLowerCase() == 'in_transit') {
          _hasNotifiedNearby = false;
        }
      }
    } catch (e) {
      print('❌ Error handling order status change: $e');
    }
  }

  /// Calculate distance between two coordinates in kilometers (Haversine formula)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371; // Earth's radius in kilometers

    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = (sin(dLat / 2) * sin(dLat / 2)) +
        (cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) * sin(dLon / 2));

    final c = 2 * asin(sqrt(a));

    return earthRadius * c;
  }

  /// Convert degrees to radians
  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  /// Listen for delivery updates from WebSocket
  void listenForDeliveryUpdates(Function(dynamic) callback) {
    websocketService.onDeliveryLocationUpdate(callback);
  }

  /// Listen for order status changes
  void listenForOrderStatusChanges(Function(dynamic) callback) {
    websocketService.onOrderStatusChange(callback);
  }

  /// Clean up resources
  void dispose() {
    stopTracking();
    websocketService.clearAllListeners();
  }
}

// Singleton instance
final realtimeDeliveryService = RealtimeDeliveryService();
