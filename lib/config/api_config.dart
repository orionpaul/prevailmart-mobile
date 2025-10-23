/// API Configuration - Customer & Driver Mobile App
/// Note: Admin/SuperAdmin features are on the website dashboard only
class ApiConfig {
  // Base URL
  static const String baseUrl = 'https://backend-prevailmart.onrender.com/api';
  static const String socketUrl = 'https://backend-prevailmart.onrender.com';

  // Auth Endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String profile = '/auth/profile';

  // Customer Endpoints
  static const String products = '/products';
  static const String featuredProducts = '/products/featured';
  static const String categories = '/categories';
  static const String cart = '/cart';
  static const String orders = '/orders';
  static const String myOrders = '/orders/my-orders';

  // Driver Endpoints
  static const String deliveries = '/deliveries';
  static const String myDeliveries = '/deliveries/my-deliveries';
  static const String acceptDelivery = '/deliveries/{id}/accept';
  static const String updateLocation = '/deliveries/{id}/location';
  static const String completeDelivery = '/deliveries/{id}/complete';

  // Storage Keys
  static const String tokenKey = 'access_token';
  static const String userKey = 'user_data';
}
