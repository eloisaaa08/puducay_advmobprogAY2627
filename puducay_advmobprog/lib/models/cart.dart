import 'product.dart';

/// Represents one product entry returned by the DummyJSON Cart endpoint.
class CartProduct {
  final int id;
  final String title;
  final double price;
  final int quantity;
  final double total;
  final double discountPercentage;
  final double discountedTotal;
  final String thumbnail;

  const CartProduct({
    required this.id,
    required this.title,
    required this.price,
    required this.quantity,
    required this.total,
    required this.discountPercentage,
    required this.discountedTotal,
    required this.thumbnail,
  });

  factory CartProduct.fromJson(Map<String, dynamic> json) {
    return CartProduct(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      quantity: json['quantity'] ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      discountPercentage:
          (json['discountPercentage'] as num?)?.toDouble() ?? 0.0,
      discountedTotal:
          ((json['discountedTotal'] ?? json['discountedPrice']) as num?)
                  ?.toDouble() ??
              0.0,
      thumbnail: json['thumbnail'] ?? '',
    );
  }

  /// Converts a cart product back to the product shape used by the
  /// existing ProductDetailScreen. This lets cart items reuse the
  /// application's existing detail screen.
  Product toProduct() {
    return Product(
      id: id,
      title: title,
      description: '',
      category: '',
      price: price,
      discountPercentage: discountPercentage,
      rating: 0.0,
      stock: 0,
      tags: const [],
      brand: '',
      sku: '',
      weight: 0.0,
      dimensions: ProductDimensions(
        width: 0.0,
        height: 0.0,
        depth: 0.0,
      ),
      warrantyInformation: '',
      shippingInformation: '',
      availabilityStatus: '',
      reviews: const [],
      returnPolicy: '',
      minimumOrderQuantity: 1,
      meta: ProductMeta(
        createdAt: '',
        updatedAt: '',
        barcode: '',
        qrCode: '',
      ),
      images: thumbnail.isEmpty ? const [] : [thumbnail],
      thumbnail: thumbnail,
    );
  }
}

/// Represents the complete cart returned by DummyJSON.
class Cart {
  final int id;
  final List<CartProduct> products;
  final double total;
  final double discountedTotal;
  final int userId;
  final int totalProducts;
  final int totalQuantity;

  const Cart({
    required this.id,
    required this.products,
    required this.total,
    required this.discountedTotal,
    required this.userId,
    required this.totalProducts,
    required this.totalQuantity,
  });

  factory Cart.fromJson(Map<String, dynamic> json) {
    final productsJson = json['products'] as List? ?? [];

    return Cart(
      id: json['id'] ?? 0,
      products: productsJson
          .map(
            (item) => CartProduct.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      discountedTotal:
          ((json['discountedTotal'] ?? json['discountedPrice']) as num?)
                  ?.toDouble() ??
              0.0,
      userId: json['userId'] ?? 0,
      totalProducts: json['totalProducts'] ?? 0,
      totalQuantity: json['totalQuantity'] ?? 0,
    );
  }
}
