class ReviewUser {
  final String id;
  final String name;
  final String email;

  ReviewUser({
    required this.id,
    required this.name,
    required this.email,
  });

  factory ReviewUser.fromJson(Map<String, dynamic> json) {
    return ReviewUser(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
    };
  }
}

class Review {
  final String id;
  final String product;
  final ReviewUser user;
  final String? order;
  final int rating;
  final String? comment;
  final bool isVerifiedPurchase;
  final int helpfulCount;
  final List<String> helpfulBy;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Review({
    required this.id,
    required this.product,
    required this.user,
    this.order,
    required this.rating,
    this.comment,
    required this.isVerifiedPurchase,
    required this.helpfulCount,
    required this.helpfulBy,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['_id'] ?? '',
      product: json['product'] ?? '',
      user: ReviewUser.fromJson(json['user'] ?? {}),
      order: json['order'],
      rating: json['rating'] ?? 0,
      comment: json['comment'],
      isVerifiedPurchase: json['isVerifiedPurchase'] ?? false,
      helpfulCount: json['helpfulCount'] ?? 0,
      helpfulBy: List<String>.from(json['helpfulBy'] ?? []),
      status: json['status'] ?? 'pending',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'product': product,
      'user': user.toJson(),
      'order': order,
      'rating': rating,
      'comment': comment,
      'isVerifiedPurchase': isVerifiedPurchase,
      'helpfulCount': helpfulCount,
      'helpfulBy': helpfulBy,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class RatingStats {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingDistribution;

  RatingStats({
    required this.averageRating,
    required this.totalReviews,
    required this.ratingDistribution,
  });

  factory RatingStats.fromJson(Map<String, dynamic> json) {
    final distribution = json['ratingDistribution'] as Map<String, dynamic>? ?? {};
    return RatingStats(
      averageRating: (json['averageRating'] ?? 0.0).toDouble(),
      totalReviews: json['totalReviews'] ?? 0,
      ratingDistribution: {
        1: distribution['1'] ?? 0,
        2: distribution['2'] ?? 0,
        3: distribution['3'] ?? 0,
        4: distribution['4'] ?? 0,
        5: distribution['5'] ?? 0,
      },
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'ratingDistribution': {
        '1': ratingDistribution[1],
        '2': ratingDistribution[2],
        '3': ratingDistribution[3],
        '4': ratingDistribution[4],
        '5': ratingDistribution[5],
      },
    };
  }
}
