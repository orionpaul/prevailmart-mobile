import 'package:flutter/foundation.dart';

/// Logging utility for PrevailMart app
/// Automatically disabled in release builds for better performance
class AppLogger {
  static const String _prefix = '🛍️ PrevailMart';

  /// Log info message (blue)
  static void info(String message, [dynamic data]) {
    if (kDebugMode) {
      print('$_prefix ℹ️ $message${data != null ? ' | $data' : ''}');
    }
  }

  /// Log success message (green)
  static void success(String message, [dynamic data]) {
    if (kDebugMode) {
      print('$_prefix ✅ $message${data != null ? ' | $data' : ''}');
    }
  }

  /// Log warning message (yellow)
  static void warning(String message, [dynamic data]) {
    if (kDebugMode) {
      print('$_prefix ⚠️ $message${data != null ? ' | $data' : ''}');
    }
  }

  /// Log error message (red)
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      print('$_prefix ❌ $message${error != null ? ' | $error' : ''}');
      if (stackTrace != null) {
        print('$_prefix 📍 Stack trace: $stackTrace');
      }
    }
  }

  /// Log API request
  static void apiRequest(String method, String endpoint, [dynamic data]) {
    if (kDebugMode) {
      print('$_prefix 🌐 $method $endpoint${data != null ? ' | $data' : ''}');
    }
  }

  /// Log API response
  static void apiResponse(int statusCode, String endpoint, [dynamic data]) {
    if (kDebugMode) {
      final icon = statusCode >= 200 && statusCode < 300 ? '✅' : '❌';
      print('$_prefix $icon $statusCode $endpoint${data != null ? ' | $data' : ''}');
    }
  }

  /// Log navigation
  static void navigation(String route, [String? action]) {
    if (kDebugMode) {
      print('$_prefix 🧭 ${action ?? 'Navigating to'} $route');
    }
  }

  /// Log user action
  static void userAction(String action, [dynamic data]) {
    if (kDebugMode) {
      print('$_prefix 👤 User: $action${data != null ? ' | $data' : ''}');
    }
  }

  /// Log cart action
  static void cart(String action, [dynamic data]) {
    if (kDebugMode) {
      print('$_prefix 🛒 Cart: $action${data != null ? ' | $data' : ''}');
    }
  }

  /// Log auth action
  static void auth(String action, [dynamic data]) {
    if (kDebugMode) {
      print('$_prefix 🔐 Auth: $action${data != null ? ' | $data' : ''}');
    }
  }

  /// Log location action
  static void location(String action, [dynamic data]) {
    if (kDebugMode) {
      print('$_prefix 📍 Location: $action${data != null ? ' | $data' : ''}');
    }
  }

  /// Log order action
  static void order(String action, [dynamic data]) {
    if (kDebugMode) {
      print('$_prefix 📦 Order: $action${data != null ? ' | $data' : ''}');
    }
  }

  /// Log delivery action (for drivers)
  static void delivery(String action, [dynamic data]) {
    if (kDebugMode) {
      print('$_prefix 🚚 Delivery: $action${data != null ? ' | $data' : ''}');
    }
  }

  /// Log promotional banner action
  static void banner(String action, [dynamic data]) {
    if (kDebugMode) {
      print('$_prefix 🎯 Banner: $action${data != null ? ' | $data' : ''}');
    }
  }

  /// Log debug information (only in debug mode)
  static void debug(String message, [dynamic data]) {
    if (kDebugMode) {
      print('$_prefix 🔍 DEBUG: $message${data != null ? ' | $data' : ''}');
    }
  }
}
