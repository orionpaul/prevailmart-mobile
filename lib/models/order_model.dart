import 'cart_model.dart';

/// Order Model - Represents a customer order
class Order {
  final String id;
  final List<CartItem> items;
  final double total;
  final String status;
  final String? deliveryAddress;
  final String? paymentMethod;
  final String? trackingNumber;
  final DateTime createdAt;
  final DateTime? deliveredAt;
  final String? driverId;
  final String? driverName;
  final Map<String, dynamic>? location;

  Order({
    required this.id,
    required this.items,
    required this.total,
    required this.status,
    this.deliveryAddress,
    this.paymentMethod,
    this.trackingNumber,
    required this.createdAt,
    this.deliveredAt,
    this.driverId,
    this.driverName,
    this.location,
  });

  /// Create Order from JSON
  factory Order.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List<dynamic>? ?? [];
    final items = itemsList
        .map((item) => CartItem.fromJson(item as Map<String, dynamic>))
        .toList();

    return Order(
      id: json['_id'] ?? json['id'] ?? '',
      items: items,
      total: (json['total'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      deliveryAddress: json['deliveryAddress'],
      paymentMethod: json['paymentMethod'],
      trackingNumber: json['trackingNumber'] ?? json['orderNumber'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.parse(json['deliveredAt'])
          : null,
      driverId: json['driverId'],
      driverName: json['driverName'],
      location: json['location'],
    );
  }

  /// Convert Order to JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'items': items.map((item) => item.toJson()).toList(),
      'total': total,
      'status': status,
      'deliveryAddress': deliveryAddress,
      'paymentMethod': paymentMethod,
      'trackingNumber': trackingNumber,
      'createdAt': createdAt.toIso8601String(),
      'deliveredAt': deliveredAt?.toIso8601String(),
      'driverId': driverId,
      'driverName': driverName,
      'location': location,
    };
  }

  /// Get status display text
  String get statusDisplay {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Order Placed';
      case 'confirmed':
        return 'Confirmed';
      case 'assigned':
        return 'Driver Assigned';
      case 'picked_up':
        return 'Out for Delivery';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  /// Check if order is active (can be tracked)
  bool get isActive =>
      status != 'delivered' && status != 'cancelled';

  /// Check if order can be tracked in real-time
  bool get canTrack =>
      status == 'assigned' || status == 'picked_up';
}
