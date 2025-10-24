import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

/// WebSocket Service for real-time communication
/// Handles order updates, driver location, and notifications
class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  IO.Socket? _socket;
  final _storage = const FlutterSecureStorage();
  bool _isConnected = false;

  /// Check if socket is connected
  bool get isConnected => _isConnected;

  /// Get socket instance
  IO.Socket? get socket => _socket;

  /// Connect to WebSocket server
  Future<void> connect() async {
    if (_socket != null && _socket!.connected) {
      print('✅ WebSocket already connected');
      return;
    }

    try {
      // Get auth token
      final token = await _storage.read(key: ApiConfig.tokenKey);
      if (token == null) {
        print('❌ No auth token found');
        return;
      }

      print('🔌 Connecting to WebSocket: ${ApiConfig.socketUrl}');

      _socket = IO.io(
        ApiConfig.socketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .setAuth({'token': token})
            .enableReconnection()
            .setReconnectionDelay(3000)
            .setReconnectionAttempts(5)
            .build(),
      );

      _socket!.onConnect((_) {
        print('✅ WebSocket connected');
        _isConnected = true;
      });

      _socket!.onDisconnect((_) {
        print('⚠️ WebSocket disconnected');
        _isConnected = false;
      });

      _socket!.onConnectError((error) {
        print('❌ WebSocket connection error: $error');
        _isConnected = false;
      });

      _socket!.onError((error) {
        print('❌ WebSocket error: $error');
      });

      _socket!.connect();
    } catch (e) {
      print('❌ Error connecting to WebSocket: $e');
    }
  }

  /// Disconnect from WebSocket server
  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _isConnected = false;
      print('🔌 WebSocket disconnected');
    }
  }

  // ==================== Order Events ====================

  /// Join order room to receive updates
  void joinOrderRoom(String orderId) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('join_order', orderId);
      print('📦 Joined order room: $orderId');
    }
  }

  /// Leave order room
  void leaveOrderRoom(String orderId) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('leave_order', orderId);
      print('📦 Left order room: $orderId');
    }
  }

  /// Listen for order updates
  void onOrderUpdate(Function(dynamic) callback) {
    if (_socket != null) {
      _socket!.on('order_updated', callback);
    }
  }

  /// Listen for order status changes
  void onOrderStatusChange(Function(dynamic) callback) {
    if (_socket != null) {
      _socket!.on('order_status_changed', callback);
    }
  }

  /// Listen for delivery location updates
  void onDeliveryLocationUpdate(Function(dynamic) callback) {
    if (_socket != null) {
      _socket!.on('delivery_location_updated', callback);
    }
  }

  /// Listen for driver assignment
  void onDriverAssigned(Function(dynamic) callback) {
    if (_socket != null) {
      _socket!.on('driver_assigned', callback);
    }
  }

  // ==================== Driver Events ====================

  /// Join driver room
  void joinDriverRoom(String driverId) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('join_driver', driverId);
      print('🚗 Joined driver room: $driverId');
    }
  }

  /// Update driver location
  void updateDriverLocation(double latitude, double longitude) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('update_driver_location', {
        'latitude': latitude,
        'longitude': longitude,
      });
    }
  }

  // ==================== Admin Events ====================

  /// Listen for new orders (admin only)
  void onNewOrder(Function(dynamic) callback) {
    if (_socket != null) {
      _socket!.on('new_order', callback);
    }
  }

  // ==================== Cleanup ====================

  /// Remove event listener
  void off(String event) {
    if (_socket != null) {
      _socket!.off(event);
    }
  }

  /// Remove all listeners
  void clearAllListeners() {
    if (_socket != null) {
      _socket!.clearListeners();
    }
  }
}

// Singleton instance
final websocketService = WebSocketService();
