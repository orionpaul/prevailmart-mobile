import 'package:flutter/material.dart';
import '../config/app_colors.dart';

/// Trust Badge Model
class TrustBadge {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  TrustBadge({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}

/// Trust Badges Widget - Builds customer confidence
class TrustBadgesWidget extends StatelessWidget {
  final bool showStats;

  const TrustBadgesWidget({
    super.key,
    this.showStats = false,
  });

  @override
  Widget build(BuildContext context) {
    final badges = [
      TrustBadge(
        icon: Icons.security,
        title: '100% Secure Payment',
        description: 'Your payment info is safe',
        color: const Color(0xFF27ae60),
      ),
      TrustBadge(
        icon: Icons.local_shipping,
        title: 'Free Delivery',
        description: 'On orders over \$50',
        color: const Color(0xFF3498db),
      ),
      TrustBadge(
        icon: Icons.replay,
        title: 'Easy Returns',
        description: '30-day money-back guarantee',
        color: const Color(0xFFe74c3c),
      ),
      TrustBadge(
        icon: Icons.support_agent,
        title: '24/7 Support',
        description: 'Always here to help',
        color: const Color(0xFFf39c12),
      ),
      TrustBadge(
        icon: Icons.verified,
        title: 'Quality Guaranteed',
        description: 'Premium products only',
        color: const Color(0xFF9b59b6),
      ),
      TrustBadge(
        icon: Icons.eco,
        title: 'Fresh Products',
        description: 'Delivered fresh daily',
        color: const Color(0xFF2ecc71),
      ),
    ];

    final stats = [
      {'value': '50,000+', 'label': 'Happy Customers', 'icon': Icons.people},
      {'value': '4.8/5.0', 'label': 'Average Rating', 'icon': Icons.star},
      {
        'value': '100,000+',
        'label': 'Orders Delivered',
        'icon': Icons.shopping_bag
      },
      {
        'value': '30 min',
        'label': 'Avg. Delivery Time',
        'icon': Icons.access_time
      },
    ];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.05),
            Colors.white,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        children: [
          // Section Title
          const Text(
            'Why Choose PrevailMart?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your trusted grocery delivery partner',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),

          // Trust Badges Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
            ),
            itemCount: badges.length,
            itemBuilder: (context, index) {
              final badge = badges[index];
              return _buildBadgeCard(badge);
            },
          ),

          // Statistics Section
          if (showStats) ...[
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.grey200,
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Trusted by Thousands',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      childAspectRatio: 1.5,
                    ),
                    itemCount: stats.length,
                    itemBuilder: (context, index) {
                      final stat = stats[index];
                      return _buildStatCard(stat);
                    },
                  ),
                ],
              ),
            ),
          ],

          // Payment Methods
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.grey200),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.credit_card,
                        color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'We Accept',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildPaymentBadge('Visa', Icons.credit_card),
                    _buildPaymentBadge('Mastercard', Icons.credit_card),
                    _buildPaymentBadge('PayPal', Icons.account_balance_wallet),
                    _buildPaymentBadge('Cash', Icons.money),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeCard(TrustBadge badge) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: badge.color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: badge.color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: badge.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              badge.icon,
              size: 32,
              color: badge.color,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            badge.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            badge.description,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(Map<String, dynamic> stat) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          stat['icon'] as IconData,
          color: AppColors.primary,
          size: 32,
        ),
        const SizedBox(height: 8),
        Text(
          stat['value'] as String,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          stat['label'] as String,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentBadge(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.grey300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
