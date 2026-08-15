import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/product.dart';
import '../widgets/custom_text.dart';

class ProductDetailScreen extends StatelessWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: CustomText(
          text: 'Product Details',
          fontSize: 20.sp,
          fontWeight: FontWeight.w600,
        ),
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ============================================================
            // Enhancement 2:
            // Product details page opened when a product card is clicked.
            // ============================================================

            // Product image
            SizedBox(
              width: double.infinity,
              height: 300.h,
              child: Image.network(
                product.thumbnail,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return Center(
                    child: Icon(Icons.image_not_supported, size: 60.sp),
                  );
                },
              ),
            ),

            Padding(
              padding: EdgeInsets.all(16.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product title
                  CustomText(
                    text: product.title,
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                  ),

                  SizedBox(height: 8.h),

                  // Brand and category
                  Row(
                    children: [
                      if (product.brand.isNotEmpty)
                        CustomText(
                          text: product.brand,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),

                      if (product.brand.isNotEmpty &&
                          product.category.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.w),
                          child: const Text('•'),
                        ),

                      CustomText(text: product.category, fontSize: 14.sp),
                    ],
                  ),

                  SizedBox(height: 16.h),

                  // Price
                  CustomText(
                    text: '\$${product.price.toStringAsFixed(2)}',
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                  ),

                  SizedBox(height: 12.h),

                  // Rating
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 22.sp),
                      SizedBox(width: 5.w),
                      CustomText(
                        text: '${product.rating.toStringAsFixed(1)} / 5',
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ],
                  ),

                  SizedBox(height: 20.h),

                  // Description
                  CustomText(
                    text: 'Description',
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),

                  SizedBox(height: 8.h),

                  CustomText(text: product.description, fontSize: 14.sp),

                  SizedBox(height: 20.h),

                  // Product information
                  CustomText(
                    text: 'Product Information',
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),

                  SizedBox(height: 12.h),

                  _InfoRow(label: 'Stock', value: '${product.stock}'),

                  _InfoRow(
                    label: 'Availability',
                    value: product.availabilityStatus,
                  ),

                  _InfoRow(label: 'SKU', value: product.sku),

                  _InfoRow(label: 'Weight', value: '${product.weight}'),

                  _InfoRow(
                    label: 'Warranty',
                    value: product.warrantyInformation,
                  ),

                  _InfoRow(
                    label: 'Shipping',
                    value: product.shippingInformation,
                  ),

                  _InfoRow(label: 'Return Policy', value: product.returnPolicy),

                  SizedBox(height: 20.h),

                  // Tags
                  if (product.tags.isNotEmpty) ...[
                    CustomText(
                      text: 'Tags',
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),

                    SizedBox(height: 10.h),

                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: product.tags.map((tag) {
                        return Chip(label: Text(tag));
                      }).toList(),
                    ),
                  ],

                  SizedBox(height: 20.h),

                  // Reviews
                  if (product.reviews.isNotEmpty) ...[
                    CustomText(
                      text: 'Reviews',
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),

                    SizedBox(height: 10.h),

                    ...product.reviews.map(
                      (review) => Card(
                        margin: EdgeInsets.only(bottom: 10.h),
                        child: Padding(
                          padding: EdgeInsets.all(12.r),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.amber),
                                  SizedBox(width: 5.w),
                                  CustomText(
                                    text: '${review.rating}/5',
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ],
                              ),

                              SizedBox(height: 6.h),

                              CustomText(text: review.comment, fontSize: 14.sp),

                              SizedBox(height: 6.h),

                              CustomText(
                                text: review.reviewerName,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],

                  SizedBox(height: 30.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Small reusable widget for product information.
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110.w,
            child: CustomText(
              text: label,
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
            ),
          ),

          Expanded(
            child: CustomText(
              text: value.isEmpty ? 'N/A' : value,
              fontSize: 13.sp,
            ),
          ),
        ],
      ),
    );
  }
}
