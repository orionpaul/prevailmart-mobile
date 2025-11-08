import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/promotional_banner_model.dart';
import '../utils/logger.dart';

/// Service for managing promotional banners
class PromotionalBannerService {
  /// Fetch active banners for mobile platform
  static Future<List<PromotionalBanner>> getActiveBanners() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/promotional-banners/active?platform=mobile');

      AppLogger.banner('Fetching active banners from: $url');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        final banners = data
            .map((json) => PromotionalBanner.fromJson(json))
            .where((banner) => banner.isCurrentlyValid)
            .toList();

        AppLogger.banner('Successfully fetched ${banners.length} active banners');

        return banners;
      } else {
        AppLogger.error('Failed to fetch banners: ${response.statusCode}');
        return [];
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error fetching banners: $e', stackTrace);
      return [];
    }
  }

  /// Track banner view (analytics)
  static Future<void> trackBannerView(String bannerId) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/promotional-banners/$bannerId/view');

      await http.post(url);

      AppLogger.banner('Tracked view for banner: $bannerId');
    } catch (e) {
      AppLogger.error('Error tracking banner view: $e');
    }
  }

  /// Track banner click (analytics)
  static Future<void> trackBannerClick(String bannerId) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/promotional-banners/$bannerId/click');

      await http.post(url);

      AppLogger.banner('Tracked click for banner: $bannerId');
    } catch (e) {
      AppLogger.error('Error tracking banner click: $e');
    }
  }

  /// Get banners by type
  static Future<List<PromotionalBanner>> getBannersByType(String type) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/promotional-banners/type/$type');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        return data
            .map((json) => PromotionalBanner.fromJson(json))
            .where((banner) => banner.isCurrentlyValid)
            .toList();
      } else {
        return [];
      }
    } catch (e) {
      AppLogger.error('Error fetching banners by type: $e');
      return [];
    }
  }
}
