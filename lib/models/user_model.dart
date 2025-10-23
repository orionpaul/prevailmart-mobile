/// User Model - Represents authenticated user with role
class User {
  final String id;
  final String email;
  final String name;
  final String role; // 'customer', 'driver', 'admin', or 'superadmin'
  final String? phone;
  final String? address;
  final String? profileImage;

  // Driver-specific fields
  final String? vehicleId;
  final String? licenseNumber;
  final bool? isAvailable;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.phone,
    this.address,
    this.profileImage,
    this.vehicleId,
    this.licenseNumber,
    this.isAvailable,
  });

  /// Create User from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? 'customer',
      phone: json['phone'],
      address: json['address'],
      profileImage: json['profileImage'],
      vehicleId: json['vehicleId'],
      licenseNumber: json['licenseNumber'],
      isAvailable: json['isAvailable'],
    );
  }

  /// Convert User to JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'email': email,
      'name': name,
      'role': role,
      'phone': phone,
      'address': address,
      'profileImage': profileImage,
      'vehicleId': vehicleId,
      'licenseNumber': licenseNumber,
      'isAvailable': isAvailable,
    };
  }

  /// Check if user is a driver
  bool get isDriver => role == 'driver';

  /// Check if user is a customer
  bool get isCustomer => role == 'customer';

  /// Copy with method for updates
  User copyWith({
    String? id,
    String? email,
    String? name,
    String? role,
    String? phone,
    String? address,
    String? profileImage,
    String? vehicleId,
    String? licenseNumber,
    bool? isAvailable,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      profileImage: profileImage ?? this.profileImage,
      vehicleId: vehicleId ?? this.vehicleId,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}
