import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/app_colors.dart';
import '../../models/order_model.dart';
import 'track_order_screen.dart';

/// Order Details Screen - Complete order information
class OrderDetailsScreen extends StatelessWidget {
  final Order order;

  const OrderDetailsScreen({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Text(
          'Order #${order.id.substring(order.id.length - 6).toUpperCase()}',
          style: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Status Card
            _buildStatusCard(),

            const SizedBox(height: 12),

            // Delivery Address Card
            if (order.deliveryAddress != null) _buildDeliveryAddressCard(),

            const SizedBox(height: 12),

            // Items Card
            _buildItemsCard(),

            const SizedBox(height: 12),

            // Payment Summary Card
            _buildPaymentSummaryCard(),

            const SizedBox(height: 12),

            // Order Timeline Card
            _buildTimelineCard(),

            const SizedBox(height: 20),

            // Action Buttons
            _buildActionButtons(context),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildStatusIcon(),
          const SizedBox(height: 16),
          Text(
            _getStatusTitle(),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getStatusSubtitle(),
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _getStatusColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: _getStatusColor(),
                ),
                const SizedBox(width: 6),
                Text(
                  DateFormat('MMM dd, yyyy · HH:mm').format(order.createdAt),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon() {
    IconData icon;
    Color color;

    switch (order.status.toLowerCase()) {
      case 'pending':
        icon = Icons.schedule;
        color = AppColors.warning;
        break;
      case 'confirmed':
        icon = Icons.check_circle;
        color = AppColors.info;
        break;
      case 'assigned':
      case 'picked_up':
      case 'in_transit':
        icon = Icons.local_shipping;
        color = AppColors.secondary;
        break;
      case 'delivered':
        icon = Icons.check_circle;
        color = AppColors.success;
        break;
      case 'cancelled':
        icon = Icons.cancel;
        color = AppColors.error;
        break;
      default:
        icon = Icons.info;
        color = AppColors.grey400;
    }

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 40, color: color),
    );
  }

  String _getStatusTitle() {
    switch (order.status.toLowerCase()) {
      case 'pending':
        return 'Order Placed';
      case 'confirmed':
        return 'Order Confirmed';
      case 'assigned':
        return 'Driver Assigned';
      case 'picked_up':
        return 'Order Picked Up';
      case 'in_transit':
        return 'On The Way';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return order.statusDisplay;
    }
  }

  String _getStatusSubtitle() {
    switch (order.status.toLowerCase()) {
      case 'pending':
        return 'Your order has been received and is being processed';
      case 'confirmed':
        return 'Your order has been confirmed and will be assigned to a driver soon';
      case 'assigned':
        return 'A driver has been assigned to deliver your order';
      case 'picked_up':
        return 'Your order has been picked up and is on its way';
      case 'in_transit':
        return 'Your order is on its way to you';
      case 'delivered':
        return 'Your order has been successfully delivered';
      case 'cancelled':
        return 'This order has been cancelled';
      default:
        return 'Order status: ${order.statusDisplay}';
    }
  }

  Color _getStatusColor() {
    switch (order.status.toLowerCase()) {
      case 'pending':
        return AppColors.warning;
      case 'confirmed':
        return AppColors.info;
      case 'assigned':
      case 'picked_up':
      case 'in_transit':
        return AppColors.secondary;
      case 'delivered':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.grey400;
    }
  }

  Widget _buildDeliveryAddressCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.location_on, color: AppColors.primary, size: 24),
              SizedBox(width: 8),
              Text(
                'Delivery Address',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            order.deliveryAddress ?? 'Delivery address not specified',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.shopping_bag, color: AppColors.primary, size: 24),
              SizedBox(width: 8),
              Text(
                'Order Items',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...order.items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product image
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.grey100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: item.product.displayImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              item.product.displayImage!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.shopping_bag,
                                  color: AppColors.grey400,
                                );
                              },
                            ),
                          )
                        : const Icon(
                            Icons.shopping_bag,
                            color: AppColors.grey400,
                          ),
                  ),
                  const SizedBox(width: 12),
                  // Product details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.product.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '\$${item.product.price.toStringAsFixed(2)} × ${item.quantity}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Subtotal
                  Text(
                    '\$${item.subtotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildPaymentSummaryCard() {
    // Calculate subtotal from items
    final subtotal = order.items.fold(0.0, (sum, item) => sum + item.subtotal);
    final deliveryFee = 5.0; // Default delivery fee
    final tax = subtotal * 0.08; // 8% tax estimate

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.receipt, color: AppColors.primary, size: 24),
              SizedBox(width: 8),
              Text(
                'Payment Summary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSummaryRow('Subtotal', subtotal),
          const SizedBox(height: 12),
          _buildSummaryRow('Delivery Fee', deliveryFee),
          const SizedBox(height: 12),
          _buildSummaryRow('Tax', tax),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '\$${order.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, size: 18, color: AppColors.success),
                const SizedBox(width: 8),
                Text(
                  'Paid via ${order.paymentMethod ?? "Card"}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.history, color: AppColors.primary, size: 24),
              SizedBox(width: 8),
              Text(
                'Order Timeline',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTimelineItem(
            'Order Placed',
            DateFormat('MMM dd, yyyy · HH:mm').format(order.createdAt),
            true,
          ),
          if (order.status.toLowerCase() != 'pending')
            _buildTimelineItem(
              'Order Confirmed',
              'Confirmed by store',
              true,
            ),
          if (order.status.toLowerCase() == 'delivered')
            _buildTimelineItem(
              'Delivered',
              order.deliveredAt != null
                  ? DateFormat('MMM dd, yyyy · HH:mm').format(order.deliveredAt!)
                  : 'Successfully delivered',
              true,
            ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String title, String subtitle, bool isCompleted) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isCompleted
                  ? AppColors.primary.withOpacity(0.1)
                  : AppColors.grey100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCompleted ? Icons.check_circle : Icons.circle_outlined,
              size: 18,
              color: isCompleted ? AppColors.primary : AppColors.grey400,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isCompleted
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Track Order Button
          if (order.canTrack)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TrackOrderScreen(
                        trackingNumber: order.trackingNumber!,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.location_on),
                label: const Text(
                  'Track Order',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

          // Help & Support Button
          if (order.canTrack) const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () {
                // TODO: Open support
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Opening support...'),
                    backgroundColor: AppColors.info,
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.support_agent),
              label: const Text(
                'Help & Support',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
