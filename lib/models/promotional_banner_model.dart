/// Promotional Banner Model - Syncs with backend
class PromotionalBanner {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String? mobileImageUrl;
  final String? actionText;
  final String? actionUrl;
  final String type; // 'promotion', 'announcement', 'news', 'sale', 'new_arrival', 'event'
  final int priority;
  final String colorTheme; // 'primary', 'secondary', 'success', 'warning', 'info', 'error'
  final bool isActive;
  final DateTime? startDate;
  final DateTime? endDate;
  final int clickCount;
  final int viewCount;
  final List<String> platforms;
  final double? discountPercentage;
  final String? discountCode;
  final Map<String, dynamic>? metadata;

  PromotionalBanner({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    this.mobileImageUrl,
    this.actionText,
    this.actionUrl,
    required this.type,
    required this.priority,
    required this.colorTheme,
    required this.isActive,
    this.startDate,
    this.endDate,
    required this.clickCount,
    required this.viewCount,
    required this.platforms,
    this.discountPercentage,
    this.discountCode,
    this.metadata,
  });

  /// Get the appropriate image URL for mobile
  String get displayImage => mobileImageUrl ?? imageUrl;

  /// Check if banner is currently valid based on dates
  bool get isCurrentlyValid {
    final now = DateTime.now();

    if (startDate != null && now.isBefore(startDate!)) {
      return false;
    }

    if (endDate != null && now.isAfter(endDate!)) {
      return false;
    }

    return isActive;
  }

  factory PromotionalBanner.fromJson(Map<String, dynamic> json) {
    return PromotionalBanner(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      mobileImageUrl: json['mobileImageUrl'],
      actionText: json['actionText'],
      actionUrl: json['actionUrl'],
      type: json['type'] ?? 'promotion',
      priority: json['priority'] ?? 0,
      colorTheme: json['colorTheme'] ?? 'primary',
      isActive: json['isActive'] ?? false,
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      clickCount: json['clickCount'] ?? 0,
      viewCount: json['viewCount'] ?? 0,
      platforms: json['platforms'] != null
          ? List<String>.from(json['platforms'])
          : ['both'],
      discountPercentage: json['discountPercentage']?.toDouble(),
      discountCode: json['discountCode'],
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'mobileImageUrl': mobileImageUrl,
      'actionText': actionText,
      'actionUrl': actionUrl,
      'type': type,
      'priority': priority,
      'colorTheme': colorTheme,
      'isActive': isActive,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'clickCount': clickCount,
      'viewCount': viewCount,
      'platforms': platforms,
      'discountPercentage': discountPercentage,
      'discountCode': discountCode,
      'metadata': metadata,
    };
  }

  @override
  String toString() {
    return 'PromotionalBanner(id: $id, title: $title, type: $type)';
  }
}
