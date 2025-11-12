import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product_model.dart';

/// Cache Service - Persistent data storage with background sync
/// Products are cached locally and updated silently in background
class CacheService {
  static const String _productsKey = 'cached_products';
  static const String _categoriesKey = 'cached_categories';
  static const String _lastSyncKey = 'last_sync_timestamp';
  static const Duration _cacheValidity = Duration(minutes: 30);

  /// Save products to cache
  Future<void> cacheProducts(List<Product> products) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = products.map((p) => p.toJson()).toList();
      await prefs.setString(_productsKey, json.encode(jsonList));
      await prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
      print('✅ Cached ${products.length} products');
    } catch (e) {
      print('❌ Failed to cache products: $e');
    }
  }

  /// Get cached products
  Future<List<Product>?> getCachedProducts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_productsKey);

      if (cachedData == null) {
        print('ℹ️ No cached products found');
        return null;
      }

      final List<dynamic> jsonList = json.decode(cachedData);
      final products = jsonList.map((json) => Product.fromJson(json)).toList();

      print('✅ Loaded ${products.length} products from cache');
      return products;
    } catch (e) {
      print('❌ Failed to load cached products: $e');
      return null;
    }
  }

  /// Save categories to cache
  Future<void> cacheCategories(List<String> categories) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_categoriesKey, categories);
      print('✅ Cached ${categories.length} categories');
    } catch (e) {
      print('❌ Failed to cache categories: $e');
    }
  }

  /// Get cached categories
  Future<List<String>?> getCachedCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final categories = prefs.getStringList(_categoriesKey);

      if (categories != null) {
        print('✅ Loaded ${categories.length} categories from cache');
      }

      return categories;
    } catch (e) {
      print('❌ Failed to load cached categories: $e');
      return null;
    }
  }

  /// Check if cache is still valid
  Future<bool> isCacheValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSync = prefs.getInt(_lastSyncKey);

      if (lastSync == null) return false;

      final lastSyncTime = DateTime.fromMillisecondsSinceEpoch(lastSync);
      final difference = DateTime.now().difference(lastSyncTime);

      final isValid = difference < _cacheValidity;
      print('ℹ️ Cache ${isValid ? "valid" : "expired"} (${difference.inMinutes}m old)');

      return isValid;
    } catch (e) {
      print('❌ Failed to check cache validity: $e');
      return false;
    }
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_productsKey);
      await prefs.remove(_categoriesKey);
      await prefs.remove(_lastSyncKey);
      print('✅ Cache cleared');
    } catch (e) {
      print('❌ Failed to clear cache: $e');
    }
  }

  /// Get last sync time
  Future<DateTime?> getLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSync = prefs.getInt(_lastSyncKey);

      if (lastSync == null) return null;

      return DateTime.fromMillisecondsSinceEpoch(lastSync);
    } catch (e) {
      print('❌ Failed to get last sync time: $e');
      return null;
    }
  }
}

/// Singleton instance
final cacheService = CacheService();
