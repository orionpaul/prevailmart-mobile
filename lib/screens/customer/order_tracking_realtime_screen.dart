import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_colors.dart';
import '../../config/api_config.dart';
import '../../models/order_model.dart';
import '../../services/api_service.dart';
import '../../services/websocket_service.dart';
import '../../widgets/delivery_map_widget.dart';

/// Real-Time Order Tracking Screen with WebSocket support
class OrderTrackingRealtimeScreen extends StatefulWidget {
  final String orderId;

  const OrderTrackingRealtimeScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<OrderTrackingRealtimeScreen> createState() =>
      _OrderTrackingRealtimeScreenState();
}

class _OrderTrackingRealtimeScreenState
    extends State<OrderTrackingRealtimeScreen> {
  Order? _order;
  bool _isLoading = true;
  String? _error;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _initializeTracking();
  }

  @override
  void dispose() {
    // Leave order room and cleanup WebSocket listeners
    websocketService.leaveOrderRoom(widget.orderId);
    websocketService.off('order_status_changed');
    websocketService.off('delivery_location_updated');
    websocketService.off('driver_assigned');
    super.dispose();
  }

  Future<void> _initializeTracking() async {
    // Connect to WebSocket if not already connected
    if (!websocketService.isConnected) {
      await websocketService.connect();
    }

    // Load initial order data
    await _loadOrderData();

    // Join order room for real-time updates
    websocketService.joinOrderRoom(widget.orderId);

    // Set connection status
    setState(() {
      _isConnected = websocketService.isConnected;
    });

    // Listen for real-time updates
    _setupWebSocketListeners();
  }

  void _setupWebSocketListeners() {
    // Listen for order status changes
    websocketService.onOrderStatusChange((data) {
      if (data['orderId'] == widget.orderId) {
        setState(() {
          if (_order != null) {
            _order = Order(
              id: _order!.id,
              items: _order!.items,
              total: _order!.total,
              status: data['status'] ?? _order!.status,
              deliveryAddress: _order!.deliveryAddress,
              paymentMethod: _order!.paymentMethod,
              trackingNumber: _order!.trackingNumber,
              createdAt: _order!.createdAt,
              deliveredAt: _order!.deliveredAt,
              driverId: _order!.driverId,
              driverName: _order!.driverName,
              location: _order!.location,
              statusHistory: data['statusHistory'] != null
                  ? (data['statusHistory'] as List)
                      .map((item) => StatusHistoryEntry.fromJson(item))
                      .toList()
                  : _order!.statusHistory,
              driver: _order!.driver,
              estimatedDeliveryTime: _order!.estimatedDeliveryTime,
            );
          }
        });

        // Show notification
        _showUpdateNotification('Order status updated to ${data['status']}');
      }
    });

    // Listen for driver location updates
    websocketService.onDeliveryLocationUpdate((data) {
      if (data['orderId'] == widget.orderId && _order?.driver != null) {
        setState(() {
          final location = data['location'];
          if (location != null) {
            _order = Order(
              id: _order!.id,
              items: _order!.items,
              total: _order!.total,
              status: _order!.status,
              deliveryAddress: _order!.deliveryAddress,
              paymentMethod: _order!.paymentMethod,
              trackingNumber: _order!.trackingNumber,
              createdAt: _order!.createdAt,
              deliveredAt: _order!.deliveredAt,
              driverId: _order!.driverId,
              driverName: _order!.driverName,
              location: _order!.location,
              statusHistory: _order!.statusHistory,
              driver: DriverInfo(
                name: _order!.driver!.name,
                phone: _order!.driver!.phone,
                vehicle: _order!.driver!.vehicle,
                rating: _order!.driver!.rating,
                currentLocation: DriverLocation.fromJson(location),
              ),
              estimatedDeliveryTime: _order!.estimatedDeliveryTime,
            );
          }
        });
      }
    });

    // Listen for driver assignment
    websocketService.onDriverAssigned((data) {
      if (data['orderId'] == widget.orderId) {
        setState(() {
          if (_order != null) {
            _order = Order(
              id: _order!.id,
              items: _order!.items,
              total: _order!.total,
              status: _order!.status,
              deliveryAddress: _order!.deliveryAddress,
              paymentMethod: _order!.paymentMethod,
              trackingNumber: _order!.trackingNumber,
              createdAt: _order!.createdAt,
              deliveredAt: _order!.deliveredAt,
              driverId: _order!.driverId,
              driverName: _order!.driverName,
              location: _order!.location,
              statusHistory: _order!.statusHistory,
              driver: data['driver'] != null
                  ? DriverInfo.fromJson(data['driver'])
                  : null,
              estimatedDeliveryTime: _order!.estimatedDeliveryTime,
            );
          }
        });

        _showUpdateNotification('Driver assigned to your order');
      }
    });
  }

  void _showUpdateNotification(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.wifi, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _loadOrderData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final response = await apiService.get(
        '${ApiConfig.orders}/${widget.orderId}',
      );

      if (response.statusCode == 200) {
        setState(() {
          _order = Order.fromJson(response.data);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'Track Order',
          style: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorView()
              : _order == null
                  ? const Center(child: Text('Order not found'))
                  : RefreshIndicator(
                      onRefresh: _loadOrderData,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          children: [
                            // Connection Status Banner
                            if (_isConnected) _buildConnectionBanner(),

                            // Order Content
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Order Header
                                  _buildOrderHeader(),
                                  const SizedBox(height: 20),

                                  // Current Status Card
                                  _buildCurrentStatusCard(),
                                  const SizedBox(height: 20),

                                  // Delivery Map (if driver location available and order in transit)
                                  if (_shouldShowMap()) ...[
                                    DeliveryMapWidget(
                                      driverLocation: _order!.driver!.currentLocation!,
                                      deliveryLocation: _getDeliveryLocation(),
                                      orderStatus: _order!.status,
                                    ),
                                    const SizedBox(height: 20),
                                  ],

                                  // Driver Info (if assigned)
                                  if (_order!.driver != null) ...[
                                    _buildDriverInfo(),
                                    const SizedBox(height: 20),
                                  ],

                                  // Status Timeline
                                  if (_order!.statusHistory != null &&
                                      _order!.statusHistory!.isNotEmpty) ...[
                                    _buildStatusTimeline(),
                                    const SizedBox(height: 20),
                                  ],

                                  // Order Summary
                                  _buildOrderSummary(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildConnectionBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      color: AppColors.success.withOpacity(0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi, color: AppColors.success, size: 16),
          const SizedBox(width: 8),
          Text(
            'Real-time tracking active',
            style: TextStyle(
              color: AppColors.success,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to Load Order',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'An unknown error occurred',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadOrderData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order #${_order!.trackingNumber ?? _order!.id.substring(_order!.id.length - 8)}',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Placed on ${_formatDate(_order!.createdAt)}',
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentStatusCard() {
    final statusColor = _getStatusColor(_order!.status);
    final statusIcon = _getStatusIcon(_order!.status);
    final progress = _getProgressPercentage(_order!.status);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [statusColor, statusColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current Status',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(statusIcon, color: Colors.white, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        _order!.statusDisplay.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (_order!.estimatedDeliveryTime != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Est. Delivery',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(_order!.estimatedDeliveryTime!),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress / 100,
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getStatusMessage(_order!.status),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverInfo() {
    final driver = _order!.driver!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_pin, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Your Driver',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Driver Avatar
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              // Driver Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (index) => Icon(
                            index < driver.rating
                                ? Icons.star
                                : Icons.star_border,
                            color: AppColors.warning,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '(${driver.rating.toStringAsFixed(1)})',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.directions_car,
                            color: AppColors.textSecondary, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          driver.vehicle,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Call Driver Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _callDriver(driver.phone),
              icon: const Icon(Icons.phone, size: 20),
              label: const Text('Call Driver'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTimeline() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Order Timeline',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...(_order!.statusHistory!.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isLast = index == _order!.statusHistory!.length - 1;

            return _buildTimelineItem(
              item.status,
              item.message,
              item.timestamp,
              isLast,
            );
          }).toList()),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
    String status,
    String message,
    DateTime timestamp,
    bool isLast,
  ) {
    final color = _getStatusColor(status);
    final icon = _getStatusIcon(status);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                margin: const EdgeInsets.symmetric(vertical: 4),
                color: AppColors.grey300,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.replaceAll('_', ' ').toUpperCase(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDateTime(timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Order Summary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Items
          ...(_order!.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${item.quantity}x ${item.product.name}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
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
              ))),
          const Divider(height: 24),
          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '\$${_order!.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          // Delivery Address
          if (_order!.deliveryAddress != null) ...[
            const Divider(height: 24),
            Row(
              children: [
                Icon(Icons.location_on,
                    color: AppColors.textSecondary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _order!.deliveryAddress!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _callDriver(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not launch phone dialer'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppColors.warning;
      case 'processing':
      case 'confirmed':
        return AppColors.info;
      case 'preparing':
      case 'shipped':
      case 'out-for-delivery':
        return AppColors.primary;
      case 'delivered':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.grey400;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.schedule;
      case 'processing':
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'preparing':
        return Icons.kitchen;
      case 'shipped':
      case 'out-for-delivery':
        return Icons.local_shipping;
      case 'delivered':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  double _getProgressPercentage(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 10;
      case 'processing':
        return 20;
      case 'confirmed':
        return 30;
      case 'preparing':
        return 50;
      case 'shipped':
        return 70;
      case 'out-for-delivery':
        return 90;
      case 'delivered':
        return 100;
      case 'cancelled':
        return 0;
      default:
        return 0;
    }
  }

  String _getStatusMessage(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Your order is being confirmed';
      case 'processing':
      case 'confirmed':
        return 'Your order has been confirmed';
      case 'preparing':
        return 'Your order is being prepared';
      case 'shipped':
      case 'out-for-delivery':
        return 'Your order is on its way';
      case 'delivered':
        return 'Your order has been delivered';
      case 'cancelled':
        return 'This order has been cancelled';
      default:
        return 'Tracking your order';
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final period = time.hour >= 12 ? 'PM' : 'AM';
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${_formatDate(dateTime)} at ${_formatTime(dateTime)}';
  }

  bool _shouldShowMap() {
    // Show map if order is in transit and driver has current location
    final status = _order!.status.toLowerCase();
    return (status == 'shipped' ||
            status == 'out-for-delivery' ||
            status == 'picked_up') &&
           _order!.driver?.currentLocation != null;
  }

  DriverLocation _getDeliveryLocation() {
    // Try to get coordinates from order location first
    if (_order!.location != null &&
        _order!.location!['latitude'] != null &&
        _order!.location!['longitude'] != null) {
      return DriverLocation(
        latitude: (_order!.location!['latitude'] as num).toDouble(),
        longitude: (_order!.location!['longitude'] as num).toDouble(),
      );
    }

    // Default to Harare, Zimbabwe coordinates if no location set
    return DriverLocation(
      latitude: -17.8252,
      longitude: 31.0335,
    );
  }
}
