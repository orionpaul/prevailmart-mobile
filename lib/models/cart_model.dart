import 'product_model.dart';

/// Cart Item Model
class CartItem {
  final String productId;
  final Product product;
  int quantity;

  CartItem({
    required this.productId,
    required this.product,
    required this.quantity,
  });

  /// Create CartItem from JSON
  factory CartItem.fromJson(Map<String, dynamic> json) {
    // Safely parse product
    Map<String, dynamic> productData;
    if (json['product'] != null && json['product'] is Map<String, dynamic>) {
      productData = json['product'] as Map<String, dynamic>;
    } else {
      // Fallback to minimal product data
      productData = {
        '_id': json['productId'] ?? '',
        'name': 'Unknown Product',
        'price': 0.0,
      };
    }

    return CartItem(
      productId: json['productId'] ?? productData['_id'] ?? '',
      product: Product.fromJson(productData),
      quantity: json['quantity'] ?? 1,
    );
  }

  /// Convert CartItem to JSON
  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'product': product.toJson(),
      'quantity': quantity,
    };
  }

  /// Get subtotal for this item
  double get subtotal => product.price * quantity;
}

/// Shopping Cart Model
class Cart {
  final String? id;
  final List<CartItem> items;
  final double total;

  Cart({
    this.id,
    required this.items,
    required this.total,
  });

  /// Create Cart from JSON
  factory Cart.fromJson(Map<String, dynamic> json) {
    // Safely parse items list
    List<CartItem> items = [];
    if (json['items'] != null && json['items'] is List) {
      final itemsList = json['items'] as List;
      items = itemsList
          .map((item) {
            if (item is Map<String, dynamic>) {
              return CartItem.fromJson(item);
            }
            return null;
          })
          .whereType<CartItem>()
          .toList();
    }

    return Cart(
      id: json['_id'] ?? json['id'],
      items: items,
      total: (json['total'] ?? 0).toDouble(),
    );
  }

  /// Convert Cart to JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'items': items.map((item) => item.toJson()).toList(),
      'total': total,
    };
  }

  /// Get total items count
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  /// Check if cart is empty
  bool get isEmpty => items.isEmpty;

  /// Check if cart has items
  bool get isNotEmpty => items.isNotEmpty;

  /// Calculate total
  double get calculatedTotal =>
      items.fold(0.0, (sum, item) => sum + item.subtotal);
}
