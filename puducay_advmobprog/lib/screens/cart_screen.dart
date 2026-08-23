import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/cart.dart';
import '../services/cart_service.dart';
import '../widgets/custom_text.dart';
import 'detail_screen.dart';

/// Enhancement 1:
/// A dedicated cart screen renders the Cart API and makes each
/// cart item clickable so the existing detail screen can be reused.
///
/// Enhancement 3:
/// userId is passed to the screen so the API can request only
/// the selected user's cart.
class CartScreen extends StatefulWidget {
  final int userId;

  const CartScreen({
    super.key,
    this.userId = 1,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartService _cartService = CartService();
  late Future<Cart?> _cartFuture;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  void _loadCart() {
    _cartFuture = _cartService.getCartByUserId(widget.userId);
  }

  Future<void> _refreshCart() async {
    setState(_loadCart);
    await _cartFuture;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<Cart?>(
        future: _cartFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return _ErrorState(
              message: 'Unable to load your cart.',
              onRetry: () {
                setState(_loadCart);
              },
            );
          }

          final cart = snapshot.data;

          if (cart == null || cart.products.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refreshCart,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(24.r),
                children: [
                  SizedBox(height: 80.h),
                  Icon(Icons.shopping_cart_outlined, size: 72.sp),
                  SizedBox(height: 16.h),
                  CustomText(
                    text: 'Your cart is empty',
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w600,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8.h),
                  CustomText(
                    text: 'Add products from the Shop tab to see them here.',
                    fontSize: 14.sp,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshCart,
            child: Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
                    itemCount: cart.products.length,
                    separatorBuilder: (_, __) => SizedBox(height: 10.h),
                    itemBuilder: (context, index) {
                      final cartProduct = cart.products[index];

                      // Enhancement 1:
                      // Each cart item is clickable and opens the same
                      // detail screen already used by the product list.
                      return Card(
                        elevation: 1.5,
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DetailScreen(
                                  productId: cartProduct.id,
                                  cartProduct: cartProduct,
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: EdgeInsets.all(10.r),
                            child: Row(
                              children: [
                                _ProductThumbnail(
                                  url: cartProduct.thumbnail,
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      CustomText(
                                        text: cartProduct.title,
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w600,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: 4.h),
                                      CustomText(
                                        text:
                                            'Qty: ${cartProduct.quantity} × \$${cartProduct.price.toStringAsFixed(2)}',
                                        fontSize: 12.sp,
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                CustomText(
                                  text:
                                      '\$${cartProduct.discountedTotal.toStringAsFixed(2)}',
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Cart summary follows the API's total and discountedTotal.
                SafeArea(
                  top: false,
                  child: Container(
                    padding: EdgeInsets.fromLTRB(
                      16.w,
                      12.h,
                      16.w,
                      10.h,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 8,
                          offset: const Offset(0, -2),
                          color: Colors.black.withValues(alpha: 0.08),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomText(
                                text: 'Total',
                                fontSize: 12.sp,
                              ),
                              SizedBox(height: 2.h),
                              CustomText(
                                text:
                                    '\$${cart.discountedTotal.toStringAsFixed(2)}',
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Checkout is ready for the next activity.',
                                ),
                              ),
                            );
                          },
                          child: const Text('Checkout'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProductThumbnail extends StatelessWidget {
  final String url;

  const _ProductThumbnail({required this.url});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.r),
      child: SizedBox(
        width: 58.w,
        height: 58.w,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            alignment: Alignment.center,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Icon(Icons.image_not_supported_outlined, size: 24.sp),
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 56.sp),
            SizedBox(height: 12.h),
            CustomText(
              text: message,
              fontSize: 15.sp,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12.h),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
