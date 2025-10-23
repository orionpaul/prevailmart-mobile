import 'package:flutter/foundation.dart';
import '../models/cart_model.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../config/api_config.dart';

/// Cart Provider - Manages shopping cart state
/// Supports both authenticated (server) and guest (local) carts
class CartProvider with ChangeNotifier {
  Cart? _cart;
  bool _isLoading = false;
  String? _error;
  bool _isAuthenticated = false;

  // Getters
  Cart? get cart => _cart;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get itemCount => _cart?.itemCount ?? 0;
  double get total => _cart?.total ?? 0.0;
  bool get isEmpty => _cart?.isEmpty ?? true;
  bool get isNotEmpty => _cart?.isNotEmpty ?? false;

  /// Set authentication status
  void setAuthenticated(bool isAuth) {
    _isAuthenticated = isAuth;
  }

  /// Fetch cart from API (authenticated) or local storage (guest)
  Future<void> fetchCart() async {
    print('🛒 Fetching cart (Auth: $_isAuthenticated)...');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (_isAuthenticated) {
        // Authenticated - fetch from server
        print('📡 GET ${ApiConfig.cart}');
        final response = await apiService.get(ApiConfig.cart);

        print('📬 Response status: ${response.statusCode}');
        print('📬 Response data: ${response.data}');

        if (response.statusCode == 200) {
          final dynamic responseData = response.data;

          // Handle different response formats
          if (responseData is Map<String, dynamic>) {
            // Check if cart is nested in response
            if (responseData.containsKey('cart')) {
              _cart = Cart.fromJson(responseData['cart']);
            } else if (responseData.containsKey('data')) {
              _cart = Cart.fromJson(responseData['data']);
            } else {
              // Assume the whole response is the cart
              _cart = Cart.fromJson(responseData);
            }
          } else {
            _cart = Cart(items: [], total: 0.0);
          }

          print('✅ Cart fetched from server: ${_cart?.itemCount} items');
          print('📦 Cart items: ${_cart?.items.map((i) => i.product.name).toList()}');
        }
      } else {
        // Guest - load from local storage
        print('💾 Loading guest cart from local storage');
        final cartData = await storageService.getJson('guest_cart');
        if (cartData != null) {
          _cart = Cart.fromJson(cartData);
          print('✅ Cart loaded from local storage: ${_cart?.itemCount} items');
        } else {
          _cart = Cart(items: [], total: 0.0);
          print('✅ Initialized empty guest cart');
        }
      }
    } catch (e) {
      print('❌ Failed to fetch cart: $e');
      _error = e.toString();

      // Try to load from local storage as fallback
      print('🔄 Trying local storage as fallback...');
      try {
        final cartData = await storageService.getJson('guest_cart');
        if (cartData != null) {
          _cart = Cart.fromJson(cartData);
          print('✅ Loaded cart from local storage: ${_cart?.itemCount} items');
        } else {
          _cart = Cart(items: [], total: 0.0);
        }
      } catch (e2) {
        print('❌ Fallback also failed: $e2');
        _cart = Cart(items: [], total: 0.0);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Save guest cart to local storage
  Future<void> _saveGuestCart() async {
    if (!_isAuthenticated && _cart != null) {
      await storageService.saveJson('guest_cart', _cart!.toJson());
      print('💾 Guest cart saved to local storage');
    }
  }

  /// Sync guest cart to server when user logs in
  Future<void> syncGuestCartToServer() async {
    if (!_isAuthenticated) return;

    try {
      // Get guest cart from local storage
      final guestCartData = await storageService.getJson('guest_cart');
      if (guestCartData == null) {
        print('ℹ️ No guest cart to sync');
        return;
      }

      final guestCart = Cart.fromJson(guestCartData);
      if (guestCart.items.isEmpty) {
        print('ℹ️ Guest cart is empty, nothing to sync');
        // Clear guest cart from storage
        await storageService.deleteSecure('guest_cart');
        return;
      }

      print('🔄 Syncing ${guestCart.items.length} items from guest cart to server...');

      // Add each item to server cart
      for (final item in guestCart.items) {
        try {
          await apiService.post(
            ApiConfig.cart,
            data: {
              'productId': item.productId,
              'quantity': item.quantity,
            },
          );
          print('✅ Synced: ${item.product.name} x${item.quantity}');
        } catch (e) {
          print('⚠️ Failed to sync item ${item.product.name}: $e');
        }
      }

      // Clear guest cart from storage after sync
      await storageService.deleteSecure('guest_cart');
      print('✅ Guest cart synced and cleared from local storage');
    } catch (e) {
      print('❌ Failed to sync guest cart: $e');
    }
  }

  /// Add item to cart (works for both guest and authenticated)
  Future<bool> addToCart(Product product, {int quantity = 1}) async {
    print('➕ Adding to cart: ${product.name} x$quantity (Auth: $_isAuthenticated)');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (_isAuthenticated) {
        // Authenticated - try to add via API first
        print('📡 Sending request to ${ApiConfig.cart}');
        print('📦 Product ID: ${product.id}');

        try {
          final response = await apiService.post(
            ApiConfig.cart,
            data: {
              'productId': product.id,
              'quantity': quantity,
            },
          );

          print('📬 Response status: ${response.statusCode}');
          print('📬 Response data: ${response.data}');

          if (response.statusCode == 200 || response.statusCode == 201) {
            _cart = Cart.fromJson(response.data);
            print('✅ Added to cart successfully (server) - Cart now has ${_cart?.itemCount} items');
            _isLoading = false;
            notifyListeners();
            return true;
          }
        } catch (serverError) {
          print('⚠️ Server error: $serverError');
          print('🔄 Falling back to guest cart...');
          // Don't set _isAuthenticated to false, just fall through to guest cart
        }
      }

      // Guest cart (or fallback from server error)
      _cart ??= Cart(items: [], total: 0.0);

      // Create a mutable copy of items
      final updatedItems = List<CartItem>.from(_cart!.items);

      // Check if item already exists
      final existingIndex = updatedItems.indexWhere((item) => item.productId == product.id);

      if (existingIndex >= 0) {
        // Update quantity
        updatedItems[existingIndex].quantity += quantity;
      } else {
        // Add new item
        updatedItems.add(CartItem(
          productId: product.id!,
          product: product,
          quantity: quantity,
        ));
      }

      // Recalculate total
      final newTotal = updatedItems.fold(0.0, (sum, item) => sum + item.subtotal);

      // Create new cart with updated items and total
      _cart = Cart(
        id: _cart!.id,
        items: updatedItems,
        total: newTotal,
      );

      await _saveGuestCart();
      print('✅ Added to guest cart successfully - Cart now has ${_cart?.itemCount} items');
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('❌ Failed to add to cart: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update cart item quantity (works for both guest and authenticated)
  Future<bool> updateQuantity(String productId, int quantity) async {
    print('🔄 Updating quantity: $productId -> $quantity');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (quantity <= 0) {
        // Remove item if quantity is 0 or less
        return await removeFromCart(productId);
      }

      if (_isAuthenticated) {
        // Authenticated - update via API
        final response = await apiService.put(
          '${ApiConfig.cart}/$productId',
          data: {'quantity': quantity},
        );

        if (response.statusCode == 200) {
          _cart = Cart.fromJson(response.data);
          print('✅ Quantity updated (server)');
          _isLoading = false;
          notifyListeners();
          return true;
        }
      } else {
        // Guest - update local cart
        if (_cart != null) {
          final updatedItems = List<CartItem>.from(_cart!.items);
          final itemIndex = updatedItems.indexWhere((item) => item.productId == productId);

          if (itemIndex >= 0) {
            updatedItems[itemIndex].quantity = quantity;

            // Recalculate total
            final newTotal = updatedItems.fold(0.0, (sum, item) => sum + item.subtotal);

            // Create new cart with updated items and total
            _cart = Cart(
              id: _cart!.id,
              items: updatedItems,
              total: newTotal,
            );

            await _saveGuestCart();
            print('✅ Quantity updated (local)');
            _isLoading = false;
            notifyListeners();
            return true;
          }
        }
      }

      throw Exception('Failed to update quantity');
    } catch (e) {
      print('❌ Failed to update quantity: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Remove item from cart (works for both guest and authenticated)
  Future<bool> removeFromCart(String productId) async {
    print('🗑️ Removing from cart: $productId');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (_isAuthenticated) {
        // Authenticated - remove via API
        final response = await apiService.delete('${ApiConfig.cart}/$productId');

        if (response.statusCode == 200) {
          _cart = Cart.fromJson(response.data);
          print('✅ Removed from cart (server)');
          _isLoading = false;
          notifyListeners();
          return true;
        }
      } else {
        // Guest - remove from local cart
        if (_cart != null) {
          final updatedItems = List<CartItem>.from(_cart!.items);
          updatedItems.removeWhere((item) => item.productId == productId);

          // Recalculate total
          final newTotal = updatedItems.fold(0.0, (sum, item) => sum + item.subtotal);

          // Create new cart with updated items and total
          _cart = Cart(
            id: _cart!.id,
            items: updatedItems,
            total: newTotal,
          );

          await _saveGuestCart();
          print('✅ Removed from cart (local)');
          _isLoading = false;
          notifyListeners();
          return true;
        }
      }

      throw Exception('Failed to remove from cart');
    } catch (e) {
      print('❌ Failed to remove from cart: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Clear entire cart
  Future<bool> clearCart() async {
    print('🧹 Clearing cart...');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await apiService.delete(ApiConfig.cart);

      if (response.statusCode == 200) {
        _cart = Cart(items: [], total: 0.0);
        print('✅ Cart cleared');
        _isLoading = false;
        notifyListeners();
        return true;
      }

      throw Exception('Failed to clear cart');
    } catch (e) {
      print('❌ Failed to clear cart: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Get cart item for a product
  CartItem? getCartItem(String productId) {
    if (_cart == null) return null;
    try {
      return _cart!.items.firstWhere((item) => item.productId == productId);
    } catch (e) {
      return null;
    }
  }

  /// Check if product is in cart
  bool isInCart(String productId) {
    return getCartItem(productId) != null;
  }

  /// Get quantity for a product
  int getQuantity(String productId) {
    final item = getCartItem(productId);
    return item?.quantity ?? 0;
  }
}
