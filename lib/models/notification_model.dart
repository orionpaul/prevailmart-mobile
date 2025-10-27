/// Notification types for different events
enum NotificationType {
  orderConfirmed,
  driverAssigned,
  orderPickedUp,
  driverNearby,
  orderDelivered,
  orderCancelled,
  orderStatusUpdate,
  promotional,
  general,
}

/// Priority levels for notifications
enum NotificationPriority {
  low,
  medium,
  high,
  urgent,
}

/// Notification model
class NotificationModel {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final NotificationPriority priority;
  final DateTime timestamp;
  final Map<String, dynamic>? data;
  final bool isRead;
  final String? orderId;
  final String? trackingNumber;
  final String? imageUrl;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.priority = NotificationPriority.medium,
    required this.timestamp,
    this.data,
    this.isRead = false,
    this.orderId,
    this.trackingNumber,
    this.imageUrl,
  });

  /// Create from JSON
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      type: parseNotificationType(json['type']),
      priority: parsePriority(json['priority']),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      data: json['data'],
      isRead: json['isRead'] ?? false,
      orderId: json['orderId'],
      trackingNumber: json['trackingNumber'],
      imageUrl: json['imageUrl'],
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type.toString().split('.').last,
      'priority': priority.toString().split('.').last,
      'timestamp': timestamp.toIso8601String(),
      'data': data,
      'isRead': isRead,
      'orderId': orderId,
      'trackingNumber': trackingNumber,
      'imageUrl': imageUrl,
    };
  }

  /// Create a copy with updated fields
  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    NotificationPriority? priority,
    DateTime? timestamp,
    Map<String, dynamic>? data,
    bool? isRead,
    String? orderId,
    String? trackingNumber,
    String? imageUrl,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      timestamp: timestamp ?? this.timestamp,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      orderId: orderId ?? this.orderId,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  /// Parse notification type from string
  static NotificationType parseNotificationType(String? type) {
    switch (type?.toLowerCase()) {
      case 'order_confirmed':
      case 'orderconfirmed':
        return NotificationType.orderConfirmed;
      case 'driver_assigned':
      case 'driverassigned':
        return NotificationType.driverAssigned;
      case 'order_picked_up':
      case 'orderpickedup':
        return NotificationType.orderPickedUp;
      case 'driver_nearby':
      case 'drivernearby':
        return NotificationType.driverNearby;
      case 'order_delivered':
      case 'orderdelivered':
        return NotificationType.orderDelivered;
      case 'order_cancelled':
      case 'ordercancelled':
        return NotificationType.orderCancelled;
      case 'order_status_update':
      case 'orderstatusupdate':
        return NotificationType.orderStatusUpdate;
      case 'promotional':
        return NotificationType.promotional;
      default:
        return NotificationType.general;
    }
  }

  /// Parse priority from string
  static NotificationPriority parsePriority(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'low':
        return NotificationPriority.low;
      case 'medium':
        return NotificationPriority.medium;
      case 'high':
        return NotificationPriority.high;
      case 'urgent':
        return NotificationPriority.urgent;
      default:
        return NotificationPriority.medium;
    }
  }

  /// Get icon for notification type
  String get icon {
    switch (type) {
      case NotificationType.orderConfirmed:
        return '✅';
      case NotificationType.driverAssigned:
        return '🚗';
      case NotificationType.orderPickedUp:
        return '📦';
      case NotificationType.driverNearby:
        return '🔔';
      case NotificationType.orderDelivered:
        return '🎉';
      case NotificationType.orderCancelled:
        return '❌';
      case NotificationType.orderStatusUpdate:
        return '📋';
      case NotificationType.promotional:
        return '🎁';
      default:
        return '🔔';
    }
  }

  /// Check if notification should play sound
  bool get shouldPlaySound {
    return priority == NotificationPriority.high ||
        priority == NotificationPriority.urgent;
  }

  /// Check if notification should vibrate
  bool get shouldVibrate {
    return priority == NotificationPriority.high ||
        priority == NotificationPriority.urgent ||
        type == NotificationType.driverNearby;
  }
}
