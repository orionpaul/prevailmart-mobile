import 'dart:async';
import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';
import '../config/api_config.dart';

/// Product Provider - Manages products with intelligent caching
/// Uses cache-first strategy with background sync
class ProductProvider with ChangeNotifier {
  List<Product> _products = [];
  List<String> _categories = ['All'];
  bool _isLoading = false;
  bool _isSyncingInBackground = false;
  String? _error;
  Timer? _backgroundSyncTimer;

  List<Product> get products => _products;
  List<String> get categories => _categories;
  bool get isLoading => _isLoading;
  bool get isSyncingInBackground => _isSyncingInBackground;
  String? get error => _error;

  ProductProvider() {
    _initializeProducts();
    _startBackgroundSync();
  }

  /// Initialize products from cache or API
  Future<void> _initializeProducts() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Try to load from cache first
      final cachedProducts = await cacheService.getCachedProducts();
      final cachedCategories = await cacheService.getCachedCategories();

      if (cachedProducts != null && cachedProducts.isNotEmpty) {
        _products = cachedProducts;
        _categories = ['All', ...?cachedCategories];
        _isLoading = false;
        notifyListeners();

        // Check if cache is still valid
        final isCacheValid = await cacheService.isCacheValid();
        if (!isCacheValid) {
          // Cache expired, sync in background
          print('📦 Cache expired, syncing in background...');
          _syncProductsInBackground();
        } else {
          print('✅ Using valid cached products');
        }
      } else {
        // No cache, fetch from API
        print('📡 No cache, fetching from API...');
        await fetchProducts();
      }
    } catch (e) {
      print('❌ Error initializing products: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch products from API (with UI loading)
  Future<void> fetchProducts({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final response = await apiService.get(
        '${ApiConfig.featuredProducts}?page=1&limit=50',
      );

      if (response.statusCode == 200) {
        final dynamic responseData = response.data;
        List<dynamic> data;

        if (responseData is Map<String, dynamic>) {
          data = responseData['products'] ?? responseData['data'] ?? [];
        } else if (responseData is List) {
          data = responseData;
        } else {
          data = [];
        }

        _products = data.map((json) => Product.fromJson(json)).toList();

        // Cache the products
        await cacheService.cacheProducts(_products);

        _isLoading = false;
        _error = null;
        notifyListeners();
      }
    } catch (e) {
      print('❌ Failed to fetch products: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch categories from API
  Future<void> fetchCategories() async {
    try {
      final response = await apiService.get(ApiConfig.categories);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List
            ? response.data
            : response.data['data'] ?? [];

        final categoryNames = data.map((c) => c['name'].toString()).toList();
        _categories = ['All', ...categoryNames];

        // Cache categories
        await cacheService.cacheCategories(categoryNames);

        notifyListeners();
      }
    } catch (e) {
      print('❌ Failed to fetch categories: $e');
    }
  }

  /// Sync products in background (no UI disruption)
  Future<void> _syncProductsInBackground() async {
    if (_isSyncingInBackground) {
      print('⏳ Background sync already in progress');
      return;
    }

    _isSyncingInBackground = true;
    print('🔄 Starting background sync...');

    try {
      final response = await apiService.get(
        '${ApiConfig.featuredProducts}?page=1&limit=50',
      );

      if (response.statusCode == 200) {
        final dynamic responseData = response.data;
        List<dynamic> data;

        if (responseData is Map<String, dynamic>) {
          data = responseData['products'] ?? responseData['data'] ?? [];
        } else if (responseData is List) {
          data = responseData;
        } else {
          data = [];
        }

        final newProducts = data.map((json) => Product.fromJson(json)).toList();

        // Check if products actually changed
        if (_productsChanged(newProducts)) {
          print('✅ Products updated in background');
          _products = newProducts;
          await cacheService.cacheProducts(_products);
          notifyListeners();
        } else {
          print('ℹ️ No changes detected in products');
          // Update cache timestamp even if no changes
          await cacheService.cacheProducts(_products);
        }
      }
    } catch (e) {
      print('❌ Background sync failed: $e');
    } finally {
      _isSyncingInBackground = false;
    }
  }

  /// Check if products have changed
  bool _productsChanged(List<Product> newProducts) {
    if (newProducts.length != _products.length) return true;

    for (int i = 0; i < newProducts.length; i++) {
      final oldProduct = _products[i];
      final newProduct = newProducts[i];

      // Check if key fields changed
      if (oldProduct.id != newProduct.id ||
          oldProduct.name != newProduct.name ||
          oldProduct.price != newProduct.price ||
          oldProduct.stock != newProduct.stock ||
          oldProduct.isInStock != newProduct.isInStock) {
        return true;
      }
    }

    return false;
  }

  /// Start periodic background sync
  void _startBackgroundSync() {
    // Sync every 5 minutes
    _backgroundSyncTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _syncProductsInBackground(),
    );
    print('🔄 Background sync timer started (5 min intervals)');
  }

  /// Get products by category
  List<Product> getProductsByCategory(String category) {
    if (category == 'All') return _products;
    return _products
        .where((p) => p.category?.toLowerCase() == category.toLowerCase())
        .toList();
  }

  /// Search products
  List<Product> searchProducts(String query) {
    if (query.isEmpty) return _products;

    final lowerQuery = query.toLowerCase();
    return _products.where((p) {
      return p.name.toLowerCase().contains(lowerQuery) ||
          (p.category?.toLowerCase().contains(lowerQuery) ?? false) ||
          (p.brand?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  /// Get product by ID
  Product? getProductById(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Force refresh (pull-to-refresh)
  Future<void> refresh() async {
    await fetchProducts();
    await fetchCategories();
  }

  /// Clear cache and reload
  Future<void> clearCacheAndReload() async {
    await cacheService.clearCache();
    await _initializeProducts();
  }

  @override
  void dispose() {
    _backgroundSyncTimer?.cancel();
    super.dispose();
  }
}
