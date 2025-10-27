import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:prevailmart/screens/customer/home_screen_new.dart';
import '../../config/app_colors.dart';
import '../../config/api_config.dart';
import '../../models/order_model.dart';
import '../../services/api_service.dart';
import 'track_order_screen.dart';
import 'order_details_screen.dart';

/// Orders Screen - View order history
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<Order> _orders = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('🌐 GET ${ApiConfig.myOrders}');

      final response = await apiService.get(ApiConfig.myOrders);

      print('📬 Response status: ${response.statusCode}');
      print('📬 Response data: ${response.data}');

      if (response.statusCode == 200) {
        final dynamic responseData = response.data;
        List<dynamic> data;

        // Handle different response formats
        if (responseData is List) {
          data = responseData;
        } else if (responseData is Map<String, dynamic>) {
          data = responseData['orders'] ?? responseData['data'] ?? [];
        } else {
          data = [];
        }

        if (mounted) {
          setState(() {
            _orders = data.map((json) => Order.fromJson(json)).toList();
            _isLoading = false;
          });
          print('✅ Loaded ${_orders.length} orders');
        }
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error loading orders: $e');

      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
          // Show empty orders instead of error on first load
          if (_orders.isEmpty) {
            _orders = [];
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'My Orders',
          style: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const HomeScreenNew(),
            ),
          )
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _orders.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.cloud_off_outlined,
                          size: 80,
                          color: AppColors.grey400,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Connection Issue',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Unable to load your orders right now. This might be a temporary server issue.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _loadOrders,
                          icon: const Icon(Icons.refresh, color: AppColors.white),
                          label: const Text(
                            'Try Again',
                            style: TextStyle(color: AppColors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : _orders.isEmpty
                  ? _buildEmptyOrders()
                  : RefreshIndicator(
                      onRefresh: _loadOrders,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _orders.length,
                        itemBuilder: (context, index) {
                          return _buildOrderCard(_orders[index]);
                        },
                      ),
                    ),
    );
  }

  Widget _buildEmptyOrders() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: AppColors.grey300,
          ),
          const SizedBox(height: 16),
          const Text(
            'No orders yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start shopping to see your orders here!',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 12,
              ),
            ),
            child: const Text('Start Shopping'),
          ),
        ],
      ),
    );
  }

  void _showOrderOptions(Order order) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Order info header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Text(
                      'Order #${order.id.substring(order.id.length - 6).toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM dd, yyyy · HH:mm').format(order.createdAt),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Action options
              _buildActionOption(
              icon: Icons.receipt_long_outlined,
              title: 'View Order Details',
              subtitle: 'See full order information',
              onTap: () {
                Navigator.pop(context);
                _viewOrderDetails(order);
              },
            ),

            if (order.canTrack)
              _buildActionOption(
                icon: Icons.location_on_outlined,
                title: 'Track Order',
                subtitle: 'See real-time delivery status',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TrackOrderScreen(
                        trackingNumber: order.trackingNumber!,
                      ),
                    ),
                  );
                },
              ),

            if (order.status.toLowerCase() == 'pending' ||
                order.status.toLowerCase() == 'confirmed')
              _buildActionOption(
                icon: Icons.cancel_outlined,
                title: 'Cancel Order',
                subtitle: 'Request order cancellation',
                iconColor: AppColors.error,
                onTap: () {
                  Navigator.pop(context);
                  _cancelOrder(order);
                },
              ),

            if (order.status.toLowerCase() == 'delivered')
              _buildActionOption(
                icon: Icons.star_outline,
                title: 'Leave a Review',
                subtitle: 'Rate your experience',
                onTap: () {
                  Navigator.pop(context);
                  _leaveReview(order);
                },
              ),

            _buildActionOption(
              icon: Icons.refresh,
              title: 'Reorder Items',
              subtitle: 'Add these items to cart again',
              onTap: () {
                Navigator.pop(context);
                _reorderItems(order);
              },
            ),

            _buildActionOption(
              icon: Icons.download_outlined,
              title: 'Download Receipt',
              subtitle: 'Get a copy of your receipt',
              onTap: () {
                Navigator.pop(context);
                _downloadReceipt(order);
              },
            ),

            _buildActionOption(
              icon: Icons.support_agent_outlined,
              title: 'Contact Support',
              subtitle: 'Get help with this order',
              onTap: () {
                Navigator.pop(context);
                _contactSupport(order);
              },
            ),

            const SizedBox(height: 20),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildActionOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: (iconColor ?? AppColors.primary).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconColor ?? AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
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
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.grey400,
            ),
          ],
        ),
      ),
    );
  }

  void _viewOrderDetails(Order order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderDetailsScreen(order: order),
      ),
    );
  }

  void _cancelOrder(Order order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order?'),
        content: const Text('Are you sure you want to cancel this order? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Order'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Call cancel order API
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Order cancellation requested'),
                  backgroundColor: AppColors.warning,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Cancel Order', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _leaveReview(Order order) {
    // TODO: Navigate to review screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening review form...'),
        backgroundColor: AppColors.info,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _reorderItems(Order order) {
    // TODO: Add all items to cart
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Adding ${order.items.length} items to cart...'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _downloadReceipt(Order order) {
    // TODO: Generate and download PDF receipt
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Receipt downloaded'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _contactSupport(Order order) {
    // TODO: Open support chat or email
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening support chat...'),
        backgroundColor: AppColors.info,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    return InkWell(
      onTap: () => _showOrderOptions(order),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.id.substring(order.id.length - 6).toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                _buildStatusBadge(order.status),
              ],
            ),

            const SizedBox(height: 8),

            // Order Date
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  DateFormat('MMM dd, yyyy · HH:mm').format(order.createdAt),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            // Order Items Summary
            ...order.items.take(2).map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Text(
                      '${item.quantity}x',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.product.name,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '\$${item.subtotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),

            if (order.items.length > 2)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '+ ${order.items.length - 2} more items',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),

            const Divider(height: 24),

            // Total and View More indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '\$${order.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),

                // Tap to view more indicator
                Row(
                  children: [
                    Text(
                      'View Options',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.primary.withOpacity(0.8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: AppColors.primary.withOpacity(0.8),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'pending':
        bgColor = AppColors.warning.withOpacity(0.1);
        textColor = AppColors.warning;
        icon = Icons.schedule;
        break;
      case 'confirmed':
        bgColor = AppColors.info.withOpacity(0.1);
        textColor = AppColors.info;
        icon = Icons.check_circle_outline;
        break;
      case 'assigned':
      case 'picked_up':
        bgColor = AppColors.secondary.withOpacity(0.1);
        textColor = AppColors.secondary;
        icon = Icons.local_shipping;
        break;
      case 'delivered':
        bgColor = AppColors.success.withOpacity(0.1);
        textColor = AppColors.success;
        icon = Icons.check_circle;
        break;
      case 'cancelled':
        bgColor = AppColors.error.withOpacity(0.1);
        textColor = AppColors.error;
        icon = Icons.cancel;
        break;
      default:
        bgColor = AppColors.grey100;
        textColor = AppColors.grey600;
        icon = Icons.info_outline;
    }

    final order = Order(
      id: '',
      items: [],
      total: 0,
      status: status,
      createdAt: DateTime.now(),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 6),
          Text(
            order.statusDisplay,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
