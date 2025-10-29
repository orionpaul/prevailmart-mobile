import 'cart_model.dart';

/// Status History Entry
class StatusHistoryEntry {
  final String status;
  final DateTime timestamp;
  final String message;

  StatusHistoryEntry({
    required this.status,
    required this.timestamp,
    required this.message,
  });

  factory StatusHistoryEntry.fromJson(Map<String, dynamic> json) {
    return StatusHistoryEntry(
      status: json['status'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      message: json['message'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'timestamp': timestamp.toIso8601String(),
      'message': message,
    };
  }
}

/// Driver Location
class DriverLocation {
  final double latitude;
  final double longitude;

  DriverLocation({
    required this.latitude,
    required this.longitude,
  });

  factory DriverLocation.fromJson(Map<String, dynamic> json) {
    return DriverLocation(
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

/// Driver Information
class DriverInfo {
  final String name;
  final String phone;
  final String vehicle;
  final double rating;
  final DriverLocation? currentLocation;

  DriverInfo({
    required this.name,
    required this.phone,
    required this.vehicle,
    required this.rating,
    this.currentLocation,
  });

  factory DriverInfo.fromJson(Map<String, dynamic> json) {
    return DriverInfo(
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      vehicle: json['vehicle'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      currentLocation: json['currentLocation'] != null
          ? DriverLocation.fromJson(json['currentLocation'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'vehicle': vehicle,
      'rating': rating,
      'currentLocation': currentLocation?.toJson(),
    };
  }
}

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
  final List<StatusHistoryEntry>? statusHistory;
  final DriverInfo? driver;
  final DateTime? estimatedDeliveryTime;

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
    this.statusHistory,
    this.driver,
    this.estimatedDeliveryTime,
  });

  /// Create Order from JSON
  factory Order.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List<dynamic>? ?? [];
    final items = itemsList
        .map((item) => CartItem.fromJson(item as Map<String, dynamic>))
        .toList();

    // Parse status history
    final historyList = json['statusHistory'] as List<dynamic>? ?? [];
    final statusHistory = historyList
        .map((item) => StatusHistoryEntry.fromJson(item as Map<String, dynamic>))
        .toList();

    // Handle total amount from different backend field names
    double totalAmount = 0.0;
    if (json['total'] != null) {
      totalAmount = (json['total'] is int)
          ? (json['total'] as int).toDouble()
          : (json['total'] as double);
    } else if (json['totalAmount'] != null) {
      // Backend sometimes sends totalAmount instead of total
      totalAmount = (json['totalAmount'] is int)
          ? (json['totalAmount'] as int).toDouble()
          : (json['totalAmount'] as double);
    } else {
      // Fallback: Calculate from subtotal + shippingCost + tax
      final subtotal = (json['subtotal'] ?? 0).toDouble();
      final shippingCost = (json['shippingCost'] ?? 0).toDouble();
      final tax = (json['tax'] ?? 0).toDouble();
      totalAmount = subtotal + shippingCost + tax;
    }

    // Handle delivery address formatting
    String? formattedAddress;
    if (json['deliveryAddress'] != null) {
      if (json['deliveryAddress'] is String) {
        formattedAddress = json['deliveryAddress'] as String;
      } else if (json['deliveryAddress'] is Map) {
        // If backend sends shippingAddress object, format it as string
        final addr = json['deliveryAddress'] as Map<String, dynamic>;
        formattedAddress = _formatAddress(addr);
      }
    } else if (json['shippingAddress'] != null) {
      // Backend sometimes sends shippingAddress instead of deliveryAddress
      if (json['shippingAddress'] is String) {
        formattedAddress = json['shippingAddress'] as String;
      } else if (json['shippingAddress'] is Map) {
        final addr = json['shippingAddress'] as Map<String, dynamic>;
        formattedAddress = _formatAddress(addr);
      }
    }

    // Handle tracking number from multiple possible fields
    String? trackingNum;
    if (json['trackingNumber'] != null) {
      trackingNum = json['trackingNumber'].toString();
    } else if (json['orderNumber'] != null) {
      trackingNum = json['orderNumber'].toString();
    } else if (json['_id'] != null) {
      // Fallback to order ID if no tracking number
      trackingNum = json['_id'].toString();
    }

    return Order(
      id: json['_id'] ?? json['id'] ?? '',
      items: items,
      total: totalAmount,
      status: json['status'] ?? 'pending',
      deliveryAddress: formattedAddress,
      paymentMethod: json['paymentMethod'],
      trackingNumber: trackingNum,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.parse(json['deliveredAt'])
          : null,
      driverId: json['driverId'],
      driverName: json['driverName'],
      location: json['location'],
      statusHistory: statusHistory.isNotEmpty ? statusHistory : null,
      driver: json['driver'] != null
          ? DriverInfo.fromJson(json['driver'])
          : null,
      estimatedDeliveryTime: json['estimatedDeliveryTime'] != null
          ? DateTime.parse(json['estimatedDeliveryTime'])
          : null,
    );
  }

  /// Helper to format address object into a string
  static String _formatAddress(Map<String, dynamic> addr) {
    final parts = <String>[];

    if (addr['street'] != null && addr['street'].toString().isNotEmpty) {
      parts.add(addr['street'].toString());
    }
    if (addr['city'] != null && addr['city'].toString().isNotEmpty) {
      parts.add(addr['city'].toString());
    }
    if (addr['state'] != null && addr['state'].toString().isNotEmpty) {
      parts.add(addr['state'].toString());
    }
    if (addr['zipCode'] != null && addr['zipCode'].toString().isNotEmpty) {
      parts.add(addr['zipCode'].toString());
    } else if (addr['postalCode'] != null && addr['postalCode'].toString().isNotEmpty) {
      parts.add(addr['postalCode'].toString());
    }
    if (addr['country'] != null && addr['country'].toString().isNotEmpty) {
      parts.add(addr['country'].toString());
    }

    return parts.isEmpty ? 'No address provided' : parts.join(', ');
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
      'statusHistory': statusHistory?.map((item) => item.toJson()).toList(),
      'driver': driver?.toJson(),
      'estimatedDeliveryTime': estimatedDeliveryTime?.toIso8601String(),
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
