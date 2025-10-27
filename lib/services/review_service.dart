import '../models/review_model.dart';
import 'api_service.dart';

/// Review Service - Handles all review-related API calls
class ReviewService {
  /// Get reviews for a product
  Future<List<Review>> getProductReviews({
    required String productId,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await apiService.get(
        '/reviews',
        queryParameters: {
          'productId': productId,
          'page': page,
          'limit': limit,
        },
      );

      if (response.data != null && response.data['data'] != null) {
        final List<dynamic> reviewsJson = response.data['data'];
        return reviewsJson.map((json) => Review.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      print('❌ Error getting product reviews: $e');
      rethrow;
    }
  }

  /// Get rating stats for a product
  Future<RatingStats> getProductRatingStats(String productId) async {
    try {
      final response = await apiService.get('/reviews/product/$productId/stats');

      if (response.data != null) {
        return RatingStats.fromJson(response.data);
      }

      return RatingStats(
        averageRating: 0.0,
        totalReviews: 0,
        ratingDistribution: {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
      );
    } catch (e) {
      print('❌ Error getting rating stats: $e');
      rethrow;
    }
  }

  /// Get user's own reviews
  Future<List<Review>> getUserReviews({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await apiService.get(
        '/reviews',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      if (response.data != null && response.data['data'] != null) {
        final List<dynamic> reviewsJson = response.data['data'];
        return reviewsJson.map((json) => Review.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      print('❌ Error getting user reviews: $e');
      rethrow;
    }
  }

  /// Create a new review
  Future<Review> createReview({
    required String productId,
    required int rating,
    String? comment,
    String? orderId,
  }) async {
    try {
      final response = await apiService.post(
        '/reviews',
        data: {
          'productId': productId,
          'rating': rating,
          if (comment != null && comment.isNotEmpty) 'comment': comment,
          if (orderId != null) 'orderId': orderId,
        },
      );

      return Review.fromJson(response.data);
    } catch (e) {
      print('❌ Error creating review: $e');
      rethrow;
    }
  }

  /// Update an existing review
  Future<Review> updateReview({
    required String reviewId,
    int? rating,
    String? comment,
  }) async {
    try {
      final response = await apiService.patch(
        '/reviews/$reviewId',
        data: {
          if (rating != null) 'rating': rating,
          if (comment != null) 'comment': comment,
        },
      );

      return Review.fromJson(response.data);
    } catch (e) {
      print('❌ Error updating review: $e');
      rethrow;
    }
  }

  /// Delete a review
  Future<void> deleteReview(String reviewId) async {
    try {
      await apiService.delete('/reviews/$reviewId');
    } catch (e) {
      print('❌ Error deleting review: $e');
      rethrow;
    }
  }

  /// Mark a review as helpful
  Future<Review> markReviewHelpful(String reviewId) async {
    try {
      final response = await apiService.post('/reviews/$reviewId/helpful');
      return Review.fromJson(response.data);
    } catch (e) {
      print('❌ Error marking review as helpful: $e');
      rethrow;
    }
  }
}

/// Singleton instance
final reviewService = ReviewService();
