import 'order_model.dart';

/// Vehicle Type - Matches backend vehicle types
enum VehicleType {
  motorcycle,
  bicycle,
  car,
  scooter,
}

/// Vehicle Information
class VehicleInfo {
  final VehicleType type;
  final String? licensePlate;
  final String? description;

  VehicleInfo({
    required this.type,
    this.licensePlate,
    this.description,
  });

  factory VehicleInfo.fromJson(Map<String, dynamic> json) {
    VehicleType vehicleType;
    switch (json['type']?.toString().toLowerCase()) {
      case 'car':
        vehicleType = VehicleType.car;
        break;
      case 'bicycle':
        vehicleType = VehicleType.bicycle;
        break;
      case 'scooter':
        vehicleType = VehicleType.scooter;
        break;
      case 'motorcycle':
      default:
        vehicleType = VehicleType.motorcycle;
        break;
    }

    return VehicleInfo(
      type: vehicleType,
      licensePlate: json['licensePlate'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'licensePlate': licensePlate,
      'description': description,
    };
  }

  String get displayName {
    switch (type) {
      case VehicleType.motorcycle:
        return 'Motorcycle';
      case VehicleType.bicycle:
        return 'Bicycle';
      case VehicleType.car:
        return 'Car';
      case VehicleType.scooter:
        return 'Scooter';
    }
  }
}

/// Delivery Model - Represents a delivery assignment for drivers
class Delivery {
  final String id;
  final Order order;
  final String status;
  final String? driverId;
  final DateTime? assignedAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;
  final Map<String, dynamic>? pickupLocation;
  final Map<String, dynamic>? deliveryLocation;
  final double? distance;
  final String? customerPhone;
  final VehicleInfo? vehicleInfo;

  Delivery({
    required this.id,
    required this.order,
    required this.status,
    this.driverId,
    this.assignedAt,
    this.pickedUpAt,
    this.deliveredAt,
    this.pickupLocation,
    this.deliveryLocation,
    this.distance,
    this.customerPhone,
    this.vehicleInfo,
  });

  /// Create Delivery from JSON
  factory Delivery.fromJson(Map<String, dynamic> json) {
    // Backend uses 'orderId' field which gets populated with order data
    // Check for 'orderId' first, then 'order', then fallback to json itself
    var orderData = json['orderId'] ?? json['order'];

    // If orderId/order is null or a string (not populated), use the whole json object
    // This handles cases where the order isn't populated by the backend
    if (orderData == null || orderData is String) {
      orderData = json;
    }

    return Delivery(
      id: json['_id'] ?? json['id'] ?? '',
      order: Order.fromJson(orderData as Map<String, dynamic>),
      status: json['status'] ?? 'pending',
      driverId: json['driverId'],
      assignedAt: json['assignedAt'] != null
          ? DateTime.parse(json['assignedAt'])
          : null,
      pickedUpAt: json['pickedUpAt'] != null
          ? DateTime.parse(json['pickedUpAt'])
          : null,
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.parse(json['deliveredAt'])
          : null,
      pickupLocation: json['pickupLocation'],
      deliveryLocation: json['deliveryLocation'],
      distance: json['distance']?.toDouble(),
      customerPhone: json['customerPhone'],
      vehicleInfo: json['vehicleInfo'] != null
          ? VehicleInfo.fromJson(json['vehicleInfo'])
          : null,
    );
  }

  /// Convert Delivery to JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'order': order.toJson(),
      'status': status,
      'driverId': driverId,
      'assignedAt': assignedAt?.toIso8601String(),
      'pickedUpAt': pickedUpAt?.toIso8601String(),
      'deliveredAt': deliveredAt?.toIso8601String(),
      'pickupLocation': pickupLocation,
      'deliveryLocation': deliveryLocation,
      'distance': distance,
      'customerPhone': customerPhone,
      'vehicleInfo': vehicleInfo?.toJson(),
    };
  }

  /// Get status display text
  String get statusDisplay {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Awaiting Pickup';
      case 'assigned':
        return 'Assigned to You';
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

  /// Check if delivery is active
  bool get isActive => status == 'assigned' || status == 'picked_up';

  /// Check if delivery can be picked up
  bool get canPickup => status == 'assigned';

  /// Check if delivery can be completed
  bool get canComplete => status == 'picked_up';

  /// Get estimated earnings
  double get earnings {
    // Base delivery fee + distance-based fee
    return 5.0 + (distance ?? 0) * 0.5;
  }
}
