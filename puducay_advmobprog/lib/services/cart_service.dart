import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants.dart';
import '../models/cart.dart';

class CartService {
  String get _host {
    final value = host;
    if (value == null || value.trim().isEmpty) {
      throw Exception('HOST is not configured in assets/.env');
    }
    return value.replaceFirst(RegExp(r'/+$'), '');
  }

  // ============================================================
  // LAB ACTIVITY 4 — ENHANCEMENT 3
  // Fetch only the cart that belongs to the supplied user ID.
  // DummyJSON uses GET /carts/user/{id}. The userId passed in here comes
  // from the User model HomeScreen loaded with UserService.getUser(), so
  // the cart shown always matches the signed-in account.
  // ============================================================
  Future<Cart?> getCartByUserId(int userId) async {
    final response = await http.get(Uri.parse('$_host/carts/user/$userId'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;

      final List<dynamic> cartsJson = data['carts'] as List? ?? [];

      if (cartsJson.isEmpty) {
        return null;
      }

      return Cart.fromJson(Map<String, dynamic>.from(cartsJson.first as Map));
    }

    throw Exception(
      'Failed to load cart for user $userId '
      '(status ${response.statusCode})',
    );
  }

  // ============================================================
  // Enhancement 3:
  // Add a product to a user's cart using POST /carts/add.
  // The API expects userId and a products list containing
  // the product ID and quantity.
  // ============================================================
  Future<Cart> addToCart({
    required int userId,
    required int productId,
    int quantity = 1,
  }) async {
    final response = await http.post(
      Uri.parse('$_host/carts/add'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'products': [
          {'id': productId, 'quantity': quantity},
        ],
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Cart.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }

    throw Exception(
      'Failed to add product $productId to cart '
      '(status ${response.statusCode})',
    );
  }
}
