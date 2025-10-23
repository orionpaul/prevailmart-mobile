import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../config/app_colors.dart';

/// Product Card Shimmer - Beautiful loading placeholder
class ProductCardShimmer extends StatelessWidget {
  const ProductCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Shimmer - Fixed height
            Shimmer.fromColors(
              baseColor: AppColors.grey200,
              highlightColor: AppColors.grey100,
              child: Container(
                height: 120,
                decoration: const BoxDecoration(
                  color: AppColors.grey200,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
              ),
            ),

            // Content - Flexible to fit remaining space
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title Shimmer
                    Shimmer.fromColors(
                      baseColor: AppColors.grey200,
                      highlightColor: AppColors.grey100,
                      child: Container(
                        height: 12,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.grey200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Price Shimmer
                    Shimmer.fromColors(
                      baseColor: AppColors.grey200,
                      highlightColor: AppColors.grey100,
                      child: Container(
                        height: 14,
                        width: 50,
                        decoration: BoxDecoration(
                          color: AppColors.grey200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Button Shimmer
                    Shimmer.fromColors(
                      baseColor: AppColors.grey200,
                      highlightColor: AppColors.grey100,
                      child: Container(
                        height: 34,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.grey200,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
