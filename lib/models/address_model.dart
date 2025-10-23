/// Address Model - Delivery address with coordinates
class Address {
  final String? id;
  final String label; // Home, Work, Other
  final String fullAddress;
  final String? street;
  final String? city;
  final String? state;
  final String? zipCode;
  final String? country;
  final double latitude;
  final double longitude;
  final String? instructions; // Delivery instructions
  final bool isDefault;

  Address({
    this.id,
    required this.label,
    required this.fullAddress,
    this.street,
    this.city,
    this.state,
    this.zipCode,
    this.country,
    required this.latitude,
    required this.longitude,
    this.instructions,
    this.isDefault = false,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['_id'] ?? json['id'],
      label: json['label'] ?? 'Other',
      fullAddress: json['fullAddress'] ?? json['address'] ?? '',
      street: json['street'],
      city: json['city'],
      state: json['state'],
      zipCode: json['zipCode'] ?? json['zip'],
      country: json['country'],
      latitude: (json['latitude'] ?? json['lat'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? json['lng'] ?? 0.0).toDouble(),
      instructions: json['instructions'] ?? json['deliveryInstructions'],
      isDefault: json['isDefault'] ?? json['default'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'label': label,
      'fullAddress': fullAddress,
      if (street != null) 'street': street,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (zipCode != null) 'zipCode': zipCode,
      if (country != null) 'country': country,
      'latitude': latitude,
      'longitude': longitude,
      if (instructions != null) 'instructions': instructions,
      'isDefault': isDefault,
    };
  }

  /// Short display address (for UI)
  String get shortAddress {
    if (city != null && state != null) {
      return '$city, $state';
    }
    // Fallback to first 50 characters of full address
    if (fullAddress.length > 50) {
      return '${fullAddress.substring(0, 47)}...';
    }
    return fullAddress;
  }

  /// Copy with method for updates
  Address copyWith({
    String? id,
    String? label,
    String? fullAddress,
    String? street,
    String? city,
    String? state,
    String? zipCode,
    String? country,
    double? latitude,
    double? longitude,
    String? instructions,
    bool? isDefault,
  }) {
    return Address(
      id: id ?? this.id,
      label: label ?? this.label,
      fullAddress: fullAddress ?? this.fullAddress,
      street: street ?? this.street,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      country: country ?? this.country,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      instructions: instructions ?? this.instructions,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
