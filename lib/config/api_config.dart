import 'dart:io' show Platform;

/// API Configuration - Customer & Driver Mobile App
/// Note: Admin/SuperAdmin features are on the website dashboard only
class ApiConfig {
  // Environment configuration
  static const bool isProduction = true; // Set to true for production builds

  // Local development configuration
  // Change this to your computer's IP address when using a physical device
  static const String localIpAddress = '192.168.1.100'; // Update with your IP

  // Automatically detect platform and configure URLs
  static String get baseUrl {
    if (isProduction) {
      return 'https://prevailmart-backend.onrender.com/api';
    }

    // Local development URLs
    if (Platform.isAndroid) {
      // Android Emulator uses 10.0.2.2 to access host machine's localhost
      return 'http://10.0.2.2:3025/api';
    } else if (Platform.isIOS) {
      // iOS Simulator can use localhost directly
      return 'http://127.0.0.1:3025/api';
    } else {
      // Fallback for physical devices or other platforms
      return 'http://$localIpAddress:3025/api';
    }
  }

  static String get socketUrl {
    if (isProduction) {
      return 'https://prevailmart-backend.onrender.com';
    }

    // Local development URLs
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3025';
    } else if (Platform.isIOS) {
      return 'http://127.0.0.1:3025';
    } else {
      return 'http://$localIpAddress:3025';
    }
  }

  // Auth Endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String profile = '/auth/profile';

  // User Endpoints
  static const String users = '/users';

  // Customer Endpoints
  static const String products = '/products';
  static const String featuredProducts = '/products/featured';
  static const String categories = '/categories';
  static const String cart = '/cart';
  static const String orders = '/orders';
  // Use base /orders endpoint - backend automatically filters by authenticated user
  static const String myOrders = '/orders';

  // Driver Endpoints
  static const String deliveries = '/deliveries';
  static const String myDeliveries = '/deliveries/my-deliveries';
  static const String acceptDelivery = '/deliveries/{id}/accept';
  static const String updateLocation = '/deliveries/{id}/location';
  static const String completeDelivery = '/deliveries/{id}/complete';

  // Delivery Zones Endpoints
  static const String deliveryZones = '/delivery-zones';
  static const String deliveryZonesByLocation = '/delivery-zones/by-location';
  static const String deliveryInfo = '/delivery-zones/delivery-info';
  static const String calculateDeliveryTime = '/delivery-zones/calculate-time';

  // Storage Keys
  static const String tokenKey = 'access_token';
  static const String userKey = 'user_data';
}
