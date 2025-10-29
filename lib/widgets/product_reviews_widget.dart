import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../config/app_colors.dart';
import '../services/api_service.dart';

/// Review Model
class Review {
  final String id;
  final String userName;
  final String userId;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final bool isVerifiedPurchase;
  final int helpfulCount;
  final List<String>? images;

  Review({
    required this.id,
    required this.userName,
    required this.userId,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.isVerifiedPurchase = false,
    this.helpfulCount = 0,
    this.images,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    // Extract user info from nested user object or direct fields
    final user = json['user'];
    String userName = 'Anonymous';
    String userId = '';

    if (user is Map<String, dynamic>) {
      userName = user['name'] ?? user['firstName'] ?? 'Anonymous';
      userId = user['_id'] ?? '';
    } else if (json['userName'] != null) {
      userName = json['userName'];
      userId = json['userId'] ?? '';
    }

    // Calculate helpful count from helpfulVotes array
    int helpfulCount = 0;
    if (json['helpfulVotes'] is List) {
      helpfulCount = (json['helpfulVotes'] as List).length;
    } else if (json['helpfulCount'] is int) {
      helpfulCount = json['helpfulCount'];
    }

    return Review(
      id: json['_id'] ?? json['id'] ?? '',
      userName: userName,
      userId: userId,
      rating: (json['rating'] ?? 0).toDouble(),
      comment: json['comment'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      isVerifiedPurchase: json['isVerifiedPurchase'] ?? false,
      helpfulCount: helpfulCount,
      images: json['images'] != null
          ? List<String>.from(json['images'])
          : null,
    );
  }
}

// Create a global API service instance
final _apiService = ApiService();

/// Product Reviews Widget
class ProductReviewsWidget extends StatefulWidget {
  final String productId;
  final double averageRating;
  final int totalReviews;

  const ProductReviewsWidget({
    super.key,
    required this.productId,
    this.averageRating = 0.0,
    this.totalReviews = 0,
  });

  @override
  State<ProductReviewsWidget> createState() => _ProductReviewsWidgetState();
}

class _ProductReviewsWidgetState extends State<ProductReviewsWidget> {
  List<Review> _reviews = [];
  bool _isLoading = false;
  String _sortBy = 'recent'; // recent, helpful, rating
  bool _showWriteReview = false;
  double _userRating = 5.0;
  final _reviewController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _loadReviews() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiService.get(
        '/reviews',
        queryParameters: {
          'productId': widget.productId,
          'sortBy': _sortBy,
          'limit': 50, // Load more reviews for mobile
        },
      );

      if (response.data != null && response.data['data'] is List) {
        setState(() {
          _reviews = (response.data['data'] as List)
              .map((json) => Review.fromJson(json))
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _reviews = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading reviews: $e');
      setState(() {
        _reviews = [];
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load reviews: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _sortReviews(String sortBy) {
    setState(() {
      _sortBy = sortBy;
      switch (sortBy) {
        case 'helpful':
          _reviews.sort((a, b) => b.helpfulCount.compareTo(a.helpfulCount));
          break;
        case 'rating':
          _reviews.sort((a, b) => b.rating.compareTo(a.rating));
          break;
        case 'recent':
        default:
          _reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
    });
  }

  Future<void> _submitReview() async {
    if (_reviewController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write a review'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_reviewController.text.trim().length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write at least 10 characters'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    try {
      await _apiService.post(
        '/reviews',
        data: {
          'productId': widget.productId,
          'rating': _userRating.toInt(),
          'comment': _reviewController.text.trim(),
        },
      );

      setState(() {
        _showWriteReview = false;
        _reviewController.clear();
        _userRating = 5.0;
      });

      // Reload reviews to show the new one
      await _loadReviews();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review submitted successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      print('Error submitting review: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit review: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Reviews Header
        Row(
          children: [
            Icon(Icons.star, color: AppColors.warning, size: 24),
            const SizedBox(width: 8),
            const Text(
              'Customer Reviews',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Rating Summary
        _buildRatingSummary(),
        const SizedBox(height: 20),

        // Write Review Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _showWriteReview = !_showWriteReview;
              });
            },
            icon: Icon(
              _showWriteReview ? Icons.close : Icons.rate_review,
              size: 20,
            ),
            label: Text(_showWriteReview ? 'Cancel' : 'Write a Review'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ),

        // Write Review Form
        if (_showWriteReview) ...[
          const SizedBox(height: 20),
          _buildWriteReviewForm(),
        ],

        const SizedBox(height: 24),

        // Sort Options
        Row(
          children: [
            const Text(
              'Sort by:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildSortChip('Recent', 'recent'),
                    const SizedBox(width: 8),
                    _buildSortChip('Most Helpful', 'helpful'),
                    const SizedBox(width: 8),
                    _buildSortChip('Highest Rating', 'rating'),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Reviews List
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_reviews.isEmpty)
          _buildEmptyState()
        else
          ..._reviews.map((review) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildReviewCard(review),
              )),
      ],
    );
  }

  Widget _buildRatingSummary() {
    final ratingDistribution = {
      5: 65,
      4: 20,
      3: 10,
      2: 3,
      1: 2,
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Overall Rating
          Column(
            children: [
              Text(
                widget.averageRating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              RatingBar.builder(
                initialRating: widget.averageRating,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: true,
                itemCount: 5,
                itemSize: 20,
                ignoreGestures: true,
                itemBuilder: (context, _) => const Icon(
                  Icons.star,
                  color: AppColors.warning,
                ),
                onRatingUpdate: (rating) {},
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.totalReviews} reviews',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(width: 24),
          // Rating Distribution
          Expanded(
            child: Column(
              children: ratingDistribution.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Text(
                        '${entry.key}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.star, size: 12, color: AppColors.warning),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: entry.value / 100,
                            minHeight: 6,
                            backgroundColor: AppColors.grey300,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.warning),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${entry.value}%',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWriteReviewForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rate this product',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: RatingBar.builder(
              initialRating: _userRating,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: false,
              itemCount: 5,
              itemSize: 40,
              itemBuilder: (context, _) => const Icon(
                Icons.star,
                color: AppColors.warning,
              ),
              onRatingUpdate: (rating) {
                setState(() {
                  _userRating = rating;
                });
              },
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Write your review',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reviewController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Share your experience with this product...',
              filled: true,
              fillColor: AppColors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitReview,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Submit Review',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortChip(String label, String value) {
    final isSelected = _sortBy == value;
    return InkWell(
      onTap: () => _sortReviews(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.grey300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppColors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildReviewCard(Review review) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Info
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: Text(
                  review.userName[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          review.userName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (review.isVerifiedPurchase) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.check_circle,
                                  size: 10,
                                  color: AppColors.success,
                                ),
                                SizedBox(width: 3),
                                Text(
                                  'Verified',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        RatingBar.builder(
                          initialRating: review.rating,
                          minRating: 1,
                          direction: Axis.horizontal,
                          allowHalfRating: true,
                          itemCount: 5,
                          itemSize: 14,
                          ignoreGestures: true,
                          itemBuilder: (context, _) => const Icon(
                            Icons.star,
                            color: AppColors.warning,
                          ),
                          onRatingUpdate: (rating) {},
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timeago.format(review.createdAt),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Review Text
          Text(
            review.comment,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          // Helpful Button
          InkWell(
            onTap: () async {
              try {
                await _apiService.post('/reviews/${review.id}/helpful', data: {});
                // Reload reviews to get updated helpful count
                await _loadReviews();
              } catch (e) {
                print('Error marking review as helpful: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to mark as helpful: ${e.toString()}'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: Row(
              children: [
                Icon(
                  Icons.thumb_up_outlined,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Helpful (${review.helpfulCount})',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.rate_review_outlined,
              size: 64,
              color: AppColors.grey400,
            ),
            const SizedBox(height: 16),
            const Text(
              'No reviews yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Be the first to review this product',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
