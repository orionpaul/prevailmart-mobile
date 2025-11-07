import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../services/api_service.dart';
import '../config/api_config.dart';
import '../utils/logger.dart';

/// Favorites/Wishlist Provider
/// Manages user's favorite products with local storage backup
class FavoritesProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  List<String> _favoriteIds = [];
  bool _isLoading = false;
  bool _isAuthenticated = false;

  List<String> get favoriteIds => _favoriteIds;
  bool get isLoading => _isLoading;
  int get count => _favoriteIds.length;

  /// Check if product is favorited
  bool isFavorite(String productId) {
    return _favoriteIds.contains(productId);
  }

  /// Set authentication state
  void setAuthenticated(bool authenticated) {
    _isAuthenticated = authenticated;
    if (!authenticated) {
      // Clear favorites on logout
      _favoriteIds = [];
      _storage.delete(key: 'favorites');
      notifyListeners();
    }
  }

  /// Load favorites from storage or server
  Future<void> loadFavorites() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_isAuthenticated) {
        // Load from server
        AppLogger.info('Loading favorites from server');
        final response = await _apiService.get('${ApiConfig.users}/favorites');

        if (response.data != null) {
          final List<dynamic> favorites = response.data['favorites'] ?? [];
          _favoriteIds = favorites.map((f) => f.toString()).toList();
          AppLogger.success('Loaded ${_favoriteIds.length} favorites from server');

          // Save to local storage as backup
          await _saveFavoritesLocally();
        }
      } else {
        // Load from local storage
        AppLogger.info('Loading favorites from local storage');
        final stored = await _storage.read(key: 'favorites');
        if (stored != null) {
          final List<dynamic> decoded = json.decode(stored);
          _favoriteIds = decoded.map((id) => id.toString()).toList();
          AppLogger.success('Loaded ${_favoriteIds.length} favorites from storage');
        }
      }
    } catch (e) {
      AppLogger.error('Error loading favorites', e);
      // Try loading from local storage as fallback
      try {
        final stored = await _storage.read(key: 'favorites');
        if (stored != null) {
          final List<dynamic> decoded = json.decode(stored);
          _favoriteIds = decoded.map((id) => id.toString()).toList();
          AppLogger.success('Loaded favorites from local fallback');
        }
      } catch (e2) {
        AppLogger.error('Fallback loading failed', e2);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add product to favorites
  Future<bool> addToFavorites(String productId) async {
    try {
      AppLogger.userAction('Adding product to favorites', productId);

      // Optimistic update
      _favoriteIds.add(productId);
      notifyListeners();

      if (_isAuthenticated) {
        // Sync with server
        await _apiService.post(
          '${ApiConfig.users}/favorites/$productId',
          data: {},
        );
        AppLogger.success('Added to favorites on server');
      }

      // Save locally
      await _saveFavoritesLocally();
      return true;
    } catch (e) {
      AppLogger.error('Error adding to favorites', e);
      // Revert optimistic update
      _favoriteIds.remove(productId);
      notifyListeners();
      return false;
    }
  }

  /// Remove product from favorites
  Future<bool> removeFromFavorites(String productId) async {
    try {
      AppLogger.userAction('Removing product from favorites', productId);

      // Optimistic update
      _favoriteIds.remove(productId);
      notifyListeners();

      if (_isAuthenticated) {
        // Sync with server
        await _apiService.delete('${ApiConfig.users}/favorites/$productId');
        AppLogger.success('Removed from favorites on server');
      }

      // Save locally
      await _saveFavoritesLocally();
      return true;
    } catch (e) {
      AppLogger.error('Error removing from favorites', e);
      // Revert optimistic update
      _favoriteIds.add(productId);
      notifyListeners();
      return false;
    }
  }

  /// Toggle favorite status
  Future<bool> toggleFavorite(String productId) async {
    if (isFavorite(productId)) {
      return await removeFromFavorites(productId);
    } else {
      return await addToFavorites(productId);
    }
  }

  /// Save favorites to local storage
  Future<void> _saveFavoritesLocally() async {
    try {
      final encoded = json.encode(_favoriteIds);
      await _storage.write(key: 'favorites', value: encoded);
      AppLogger.debug('Favorites saved locally');
    } catch (e) {
      AppLogger.error('Error saving favorites locally', e);
    }
  }

  /// Sync local favorites to server (called after login)
  Future<void> syncFavoritesToServer() async {
    if (!_isAuthenticated || _favoriteIds.isEmpty) return;

    try {
      AppLogger.info('Syncing ${_favoriteIds.length} favorites to server');

      for (final productId in _favoriteIds) {
        try {
          await _apiService.post(
            '${ApiConfig.users}/favorites/$productId',
            data: {},
          );
        } catch (e) {
          AppLogger.warning('Failed to sync favorite: $productId', e);
        }
      }

      AppLogger.success('Favorites synced to server');
    } catch (e) {
      AppLogger.error('Error syncing favorites', e);
    }
  }

  /// Clear all favorites
  Future<void> clearFavorites() async {
    try {
      _favoriteIds.clear();
      await _storage.delete(key: 'favorites');

      if (_isAuthenticated) {
        // Clear on server too
        await _apiService.delete('${ApiConfig.users}/favorites');
      }

      notifyListeners();
      AppLogger.success('Favorites cleared');
    } catch (e) {
      AppLogger.error('Error clearing favorites', e);
    }
  }
}
