import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';

/// Secure Storage Service - Uses Flutter Secure Storage + Hive
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  late FlutterSecureStorage _secureStorage;
  late Box _box;
  bool _isInitialized = false;

  /// Initialize storage
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize Hive
    await Hive.initFlutter();
    _box = await Hive.openBox('app_storage');

    // Initialize Secure Storage
    _secureStorage = const FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
      ),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock,
      ),
    );

    _isInitialized = true;
    print('💾 Storage initialized');
  }

  /// Save string (secure)
  Future<void> saveSecure(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }

  /// Get string (secure)
  Future<String?> getSecure(String key) async {
    return await _secureStorage.read(key: key);
  }

  /// Delete secure value
  Future<void> deleteSecure(String key) async {
    await _secureStorage.delete(key: key);
  }

  /// Save to Hive (for non-sensitive data)
  Future<void> save(String key, dynamic value) async {
    await _box.put(key, value);
  }

  /// Get from Hive
  dynamic get(String key) {
    return _box.get(key);
  }

  /// Delete from Hive
  Future<void> delete(String key) async {
    await _box.delete(key);
  }

  /// Save JSON (secure)
  Future<void> saveJson(String key, Map<String, dynamic> json) async {
    await saveSecure(key, jsonEncode(json));
  }

  /// Get JSON (secure)
  Future<Map<String, dynamic>?> getJson(String key) async {
    final value = await getSecure(key);
    if (value == null) return null;
    try {
      return jsonDecode(value) as Map<String, dynamic>;
    } catch (e) {
      print('❌ Error decoding JSON: $e');
      return null;
    }
  }

  /// Clear all secure storage
  Future<void> clearSecure() async {
    await _secureStorage.deleteAll();
  }

  /// Clear all Hive storage
  Future<void> clearHive() async {
    await _box.clear();
  }

  /// Clear all storage
  Future<void> clearAll() async {
    await clearSecure();
    await clearHive();
  }
}

/// Singleton instance
final storageService = StorageService();
