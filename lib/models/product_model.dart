/// Product Model - Represents a product in the store
class Product {
  final String id;
  final String name;
  final double price;
  final String? image;
  final String? category;
  final int stock;
  final bool isFeatured;
  final String? brand;
  final List<String>? images;

  Product({
    required this.id,
    required this.name,
    required this.price,
    this.image,
    this.category,
    required this.stock,
    this.isFeatured = false,
    this.brand,
    this.images,
  });

  /// Create Product from JSON
  factory Product.fromJson(Map<String, dynamic> json) {
    // Handle category - can be String or Object
    String? categoryValue;
    if (json['category'] is String) {
      categoryValue = json['category'];
    } else if (json['category'] is Map) {
      categoryValue = json['category']['name'] ?? json['category']['_id'];
    }

    // Handle image - prioritize 'image' field, fallback to first item in 'images'
    String? imageValue = json['image'];
    List<String>? imagesList;

    // Safely parse images array
    if (json['images'] != null && json['images'] is List) {
      try {
        final List imageList = json['images'] as List;
        imagesList = imageList
            .map((e) => e?.toString() ?? '')
            .where((e) => e.isNotEmpty)
            .toList();

        // If no image value yet, use first image from list
        if (imageValue == null && imagesList.isNotEmpty) {
          imageValue = imagesList[0];
        }
      } catch (e) {
        print('Error parsing images: $e');
        imagesList = null;
      }
    }

    return Product(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      image: imageValue,
      category: categoryValue,
      stock: json['stock'] ?? 0,
      isFeatured: json['isFeatured'] ?? false,
      brand: json['brand'],
      images: imagesList,
    );
  }

  /// Convert Product to JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'price': price,
      'image': image,
      'category': category,
      'stock': stock,
      'isFeatured': isFeatured,
      'brand': brand,
      'images': images,
    };
  }

  /// Check if product is in stock
  bool get isInStock => stock > 0;

  /// Get display image
  String? get displayImage {
    if (image != null) return image;
    if (images != null && images!.isNotEmpty) return images!.first;
    return null;
  }
}
