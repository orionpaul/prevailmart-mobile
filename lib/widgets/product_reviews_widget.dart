import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../config/app_colors.dart';
import '../models/review_model.dart';
import '../services/review_service.dart';

/// Product Reviews Widget
class ProductReviewsWidget extends StatefulWidget {
  final String productId;

  const ProductReviewsWidget({
    super.key,
    required this.productId,
  });

  @override
  State<ProductReviewsWidget> createState() => _ProductReviewsWidgetState();
}

class _ProductReviewsWidgetState extends State<ProductReviewsWidget> {
  List<Review> _reviews = [];
  RatingStats? _ratingStats;
  bool _isLoading = false;
  String _sortBy = 'recent'; // recent, helpful, rating
  bool _showWriteReview = false;
  double _userRating = 5.0;
  final _reviewController = TextEditingController();
  String? _error;

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
      _error = null;
    });

    try {
      final reviews = await reviewService.getProductReviews(
        productId: widget.productId,
        page: 1,
        limit: 10,
      );

      final stats = await reviewService.getProductRatingStats(widget.productId);

      setState(() {
        _reviews = reviews;
        _ratingStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
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
    try {
      await reviewService.createReview(
        productId: widget.productId,
        rating: _userRating.toInt(),
        comment: _reviewController.text.trim().isNotEmpty
            ? _reviewController.text.trim()
            : null,
      );

      setState(() {
        _showWriteReview = false;
        _reviewController.clear();
        _userRating = 5.0;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review submitted successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }

      // Reload reviews to show the new one
      _loadReviews();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit review: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _markHelpful(String reviewId) async {
    try {
      await reviewService.markReviewHelpful(reviewId);
      _loadReviews(); // Reload to get updated helpful count
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark review as helpful: $e'),
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
    if (_ratingStats == null) {
      return const SizedBox.shrink();
    }

    final stats = _ratingStats!;

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
                stats.averageRating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              RatingBar.builder(
                initialRating: stats.averageRating,
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
                '${stats.totalReviews} ${stats.totalReviews == 1 ? "review" : "reviews"}',
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
              children: [5, 4, 3, 2, 1].map((stars) {
                final count = stats.ratingDistribution[stars] ?? 0;
                final percentage = stats.totalReviews > 0
                    ? (count / stats.totalReviews * 100).round()
                    : 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Text(
                        '$stars',
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
                            value: percentage / 100,
                            minHeight: 6,
                            backgroundColor: AppColors.grey300,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.warning),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$percentage%',
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
                  review.user.name.isNotEmpty
                      ? review.user.name[0].toUpperCase()
                      : '?',
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
                          review.user.name,
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
                          initialRating: review.rating.toDouble(),
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
          // Review Text
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              review.comment!,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppColors.textPrimary,
              ),
            ),
          ],
          const SizedBox(height: 12),
          // Helpful Button
          InkWell(
            onTap: () => _markHelpful(review.id),
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
