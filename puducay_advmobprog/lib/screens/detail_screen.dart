import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/cart.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../widgets/custom_text.dart';
import 'product_detail_screen.dart';

/// Enhancement 1:
/// Cart products contain only summary information. This screen therefore
/// uses the cart item's product ID to request the complete product from
/// GET /products/{id}, then reuses ProductDetailScreen for the actual UI.
class DetailScreen extends StatefulWidget {
  final Product? product;
  final int? productId;
  final CartProduct? cartProduct;

  const DetailScreen({
    super.key,
    this.product,
    this.productId,
    this.cartProduct,
  }) : assert(product != null || productId != null);

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late Future<Product> _productFuture;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  void _loadProduct() {
    if (widget.product != null) {
      _productFuture = Future.value(widget.product!);
      return;
    }

    _productFuture = ProductService().getProductById(widget.productId!);
  }

  Future<void> _retry() async {
    setState(_loadProduct);
    await _productFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: CustomText(
          text: 'Details',
          fontSize: 20.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: FutureBuilder<Product>(
        future: _productFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(24.r),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 48.sp),
                    SizedBox(height: 12.h),
                    CustomText(
                      text: 'Unable to load product details.',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8.h),
                    CustomText(
                      text: '${snapshot.error}',
                      fontSize: 12.sp,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16.h),
                    ElevatedButton.icon(
                      onPressed: _retry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final product = snapshot.data;
          if (product == null) {
            return const Center(child: Text('Product not found.'));
          }

          final cartProduct = widget.cartProduct;

          return ProductDetailScreen(
            product: product,
            cartQuantity: cartProduct?.quantity,
            cartTotal: cartProduct?.total,
            cartDiscountedTotal: cartProduct?.discountedTotal,
            useScaffold: false,
          );
        },
      ),
    );
  }
}
