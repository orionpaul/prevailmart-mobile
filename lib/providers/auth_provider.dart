import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../config/api_config.dart';

/// Authentication Provider - Manages auth state
class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;
  bool _isAuthenticated = false;

  // Getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;

  /// Initialize auth state from storage
  Future<void> initialize() async {
    print('🔄 Initializing auth...');
    _isLoading = true;
    notifyListeners();

    try {
      final userData = await storageService.getJson(ApiConfig.userKey);
      final token = await storageService.getSecure(ApiConfig.tokenKey);

      if (userData != null && token != null) {
        _user = User.fromJson(userData);
        _isAuthenticated = true;
        await apiService.saveToken(token);
        print('✅ User restored from storage: ${_user?.email} (${_user?.role})');
      } else {
        print('ℹ️ No stored auth data found');
      }
    } catch (e) {
      print('❌ Error initializing auth: $e');
      _error = 'Failed to restore session';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Login user
  Future<bool> login(String email, String password) async {
    print('🔐 Logging in: $email');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await apiService.post(
        ApiConfig.login,
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        final token = data['access_token'] ?? data['token'];
        final userData = data['user'];

        if (token != null && userData != null) {
          // Save token securely
          await apiService.saveToken(token);
          await storageService.saveSecure(ApiConfig.tokenKey, token);

          // Save user data securely
          _user = User.fromJson(userData);
          _isAuthenticated = true;
          await storageService.saveJson(ApiConfig.userKey, userData);

          print('✅ Login successful: ${_user?.email} (${_user?.role})');
          _isLoading = false;
          notifyListeners();
          return true;
        }
      }

      throw Exception('Invalid response format');
    } catch (e) {
      print('❌ Login failed: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Register new customer
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    String? address,
  }) async {
    print('📝 Registering customer: $email');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await apiService.post(
        ApiConfig.register,
        data: {
          'name': name,
          'email': email,
          'password': password,
          'phone': phone,
          'address': address,
          'role': 'customer', // Always register as customer
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Registration successful');
        // Auto-login after registration
        final success = await login(email, password);
        return success;
      }

      throw Exception('Registration failed');
    } catch (e) {
      print('❌ Registration failed: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Logout user
  Future<void> logout() async {
    print('🚪 Logging out');
    _isLoading = true;
    notifyListeners();

    try {
      // Clear secure storage
      await storageService.deleteSecure(ApiConfig.tokenKey);
      await storageService.deleteSecure(ApiConfig.userKey);
      await apiService.removeToken();

      // Clear state
      _user = null;
      _isAuthenticated = false;
      _error = null;

      print('✅ Logout successful');
    } catch (e) {
      print('❌ Logout error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get user profile
  Future<void> getProfile() async {
    print('👤 Fetching profile');
    _isLoading = true;
    notifyListeners();

    try {
      final response = await apiService.get(ApiConfig.profile);

      if (response.statusCode == 200) {
        _user = User.fromJson(response.data);

        // Update secure storage
        await storageService.saveJson(ApiConfig.userKey, response.data);

        print('✅ Profile fetched: ${_user?.email}');
      }
    } catch (e) {
      print('❌ Failed to fetch profile: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update user profile
  Future<bool> updateProfile(Map<String, dynamic> updates) async {
    print('✏️ Updating profile');
    _isLoading = true;
    notifyListeners();

    try {
      final response = await apiService.put(
        ApiConfig.profile,
        data: updates,
      );

      if (response.statusCode == 200) {
        _user = User.fromJson(response.data);

        // Update secure storage
        await storageService.saveJson(ApiConfig.userKey, response.data);

        print('✅ Profile updated');
        _isLoading = false;
        notifyListeners();
        return true;
      }

      throw Exception('Update failed');
    } catch (e) {
      print('❌ Profile update failed: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Refresh user data from server
  Future<void> refreshUser() async {
    print('🔄 Refreshing user data');

    try {
      final response = await apiService.get('${ApiConfig.users}/profile');

      if (response.statusCode == 200) {
        _user = User.fromJson(response.data);

        // Update secure storage
        await storageService.saveJson(ApiConfig.userKey, response.data);

        print('✅ User data refreshed');
        notifyListeners();
      }
    } catch (e) {
      print('❌ Failed to refresh user: $e');
    }
  }
}
