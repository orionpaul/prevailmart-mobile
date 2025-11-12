import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/app_colors.dart';
import '../../config/api_config.dart';
import '../../models/order_model.dart';
import '../../services/api_service.dart';
import 'customer_main_screen.dart';
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

  Future<void> _deleteOrder(Order order) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.warning, color: AppColors.error),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Warning: This action cannot be undone.',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Are you sure you want to delete this order?'),
            const SizedBox(height: 8),
            Text(
              'Order #${order.id.substring(order.id.length - 6).toUpperCase()}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                  ),
                ),
                SizedBox(width: 12),
                Text('Deleting order...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

      print('🗑️ DELETE ${ApiConfig.orders}/${order.id}');
      final response = await apiService.delete('${ApiConfig.orders}/${order.id}');

      print('📬 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.white),
                  SizedBox(width: 12),
                  Text('Order deleted successfully'),
                ],
              ),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 2),
            ),
          );

          // Reload orders
          _loadOrders();
        }
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error deleting order: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: AppColors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    e.toString().replaceAll('Exception: ', ''),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
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
          onPressed: () {
            // Use Navigator.pop() to properly go back instead of pushing a new screen
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              // If can't pop, switch to home tab
              CustomerMainScreen.switchTab(context, 0);
            }
          },
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
            onPressed: () {
              // Navigate to home tab instead of popping
              CustomerMainScreen.switchTab(context, 0);
            },
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

  Widget _buildOrderCard(Order order) {
    return GestureDetector(
      onTap: () {
        // Navigate to order details screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderDetailsScreen(order: order),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.grey300.withOpacity(0.3),
              blurRadius: 4,
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

          // Total and Actions
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

              // Action Buttons
              Row(
                children: [
                  // Track Order Button
                  if (order.canTrack && order.trackingNumber != null)
                    ElevatedButton.icon(
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
                        backgroundColor: AppColors.secondary,
                        foregroundColor: AppColors.white,
                      ),
                      icon: const Icon(Icons.location_on, size: 18),
                      label: const Text('Track'),
                    ),

                  // Delete Button (only for cancelled or delivered orders)
                  if (order.status.toLowerCase() == 'cancelled' ||
                      order.status.toLowerCase() == 'delivered')
                    Padding(
                      padding: EdgeInsets.only(
                        left: (order.canTrack && order.trackingNumber != null) ? 8 : 0,
                      ),
                      child: IconButton(
                        onPressed: () => _deleteOrder(order),
                        icon: const Icon(Icons.delete_outline),
                        color: AppColors.error,
                        tooltip: 'Delete Order',
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.error.withOpacity(0.1),
                        ),
                      ),
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
