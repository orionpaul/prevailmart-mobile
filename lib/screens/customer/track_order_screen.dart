import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/api_config.dart';
import '../../models/delivery_model.dart';
import '../../services/api_service.dart';
import 'dart:async';

/// Track Order Screen - Real-time order tracking
class TrackOrderScreen extends StatefulWidget {
  final String trackingNumber;

  const TrackOrderScreen({
    super.key,
    required this.trackingNumber,
  });

  @override
  State<TrackOrderScreen> createState() => _TrackOrderScreenState();
}

class _TrackOrderScreenState extends State<TrackOrderScreen> {
  Delivery? _delivery;
  bool _isLoading = true;
  String? _error;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadDeliveryDetails();
    // Auto-refresh every 15 seconds for real-time updates
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _loadDeliveryDetails(silent: true);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDeliveryDetails({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final response = await apiService.get(
        '${ApiConfig.deliveries}/track/${widget.trackingNumber}',
      );

      if (response.statusCode == 200) {
        setState(() {
          _delivery = Delivery.fromJson(response.data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!silent) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.white),
            onPressed: () => _loadDeliveryDetails(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 16),
                      Text('Failed to load tracking info: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadDeliveryDetails,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _delivery == null
                  ? const Center(child: Text('No tracking information found'))
                  : RefreshIndicator(
                      onRefresh: () => _loadDeliveryDetails(),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Status Card
                            _buildStatusCard(),
                            const SizedBox(height: 20),

                            // Order Progress Stepper
                            _buildProgressStepper(),
                            const SizedBox(height: 20),

                            // Vehicle Info (if available)
                            if (_delivery!.vehicleInfo != null) ...[
                              _buildVehicleInfo(),
                              const SizedBox(height: 20),
                            ],

                            // Tracking Number
                            _buildInfoCard(
                              'Tracking Number',
                              widget.trackingNumber,
                              Icons.tag,
                            ),
                            const SizedBox(height: 12),

                            // Delivery Address
                            if (_delivery!.deliveryLocation != null)
                              _buildInfoCard(
                                'Delivery Address',
                                _delivery!.deliveryLocation.toString(),
                                Icons.location_on,
                              ),

                            const SizedBox(height: 20),

                            // Order Items
                            _buildOrderItems(),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildStatusCard() {
    final statusColor = _getStatusColor(_delivery!.status);
    final statusIcon = _getStatusIcon(_delivery!.status);
    final isActiveTracking = !['delivered', 'cancelled'].contains(_delivery!.status.toLowerCase());

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
          // Live indicator
          if (isActiveTracking)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Live Tracking',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
            ),
          Icon(statusIcon, size: 48, color: AppColors.white),
          const SizedBox(height: 12),
          Text(
            _delivery!.statusDisplay,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getStatusMessage(_delivery!.status),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleInfo() {
    final vehicle = _delivery!.vehicleInfo!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getVehicleIcon(vehicle.type),
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vehicle.displayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (vehicle.licensePlate != null)
                  Text(
                    vehicle.licensePlate!,
                    style: const TextStyle(
                      fontSize: 14,
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

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItems() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...(_delivery!.order.items).map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${item.quantity}x ${item.product.name}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Text(
                      '\$${item.subtotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '\$${_delivery!.order.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppColors.warning;
      case 'assigned':
        return AppColors.info;
      case 'picked_up':
      case 'in_transit':
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
      case 'assigned':
        return Icons.person_pin;
      case 'picked_up':
      case 'in_transit':
        return Icons.local_shipping;
      case 'delivered':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  String _getStatusMessage(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Your order is being prepared';
      case 'assigned':
        return 'A driver has been assigned to your order';
      case 'picked_up':
      case 'in_transit':
        return 'Your order is on its way';
      case 'delivered':
        return 'Your order has been delivered';
      case 'cancelled':
        return 'This order has been cancelled';
      default:
        return 'Tracking your order';
    }
  }

  IconData _getVehicleIcon(VehicleType type) {
    switch (type) {
      case VehicleType.car:
        return Icons.directions_car;
      case VehicleType.motorcycle:
        return Icons.two_wheeler;
      case VehicleType.bicycle:
        return Icons.pedal_bike;
      case VehicleType.scooter:
        return Icons.electric_scooter;
    }
  }

  Widget _buildProgressStepper() {
    final steps = [
      {'status': 'pending', 'title': 'Order Placed', 'subtitle': 'Your order has been received'},
      {'status': 'confirmed', 'title': 'Confirmed', 'subtitle': 'Order confirmed and being prepared'},
      {'status': 'assigned', 'title': 'Driver Assigned', 'subtitle': 'A driver is assigned to your order'},
      {'status': 'picked_up', 'title': 'Picked Up', 'subtitle': 'Driver has picked up your order'},
      {'status': 'in_transit', 'title': 'On The Way', 'subtitle': 'Your order is on its way to you'},
      {'status': 'delivered', 'title': 'Delivered', 'subtitle': 'Order has been delivered'},
    ];

    final currentStatus = _delivery!.status.toLowerCase();
    int currentStepIndex = steps.indexWhere((s) => s['status'] == currentStatus);
    if (currentStepIndex == -1) currentStepIndex = 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Journey',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          ...List.generate(steps.length, (index) {
            final step = steps[index];
            final isCompleted = index <= currentStepIndex;
            final isCurrent = index == currentStepIndex;
            final isLast = index == steps.length - 1;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Step indicator
                Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted ? AppColors.primary : AppColors.grey200,
                        border: Border.all(
                          color: isCurrent ? AppColors.primary : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: Icon(
                        isCompleted ? Icons.check : Icons.circle_outlined,
                        color: isCompleted ? AppColors.white : AppColors.grey400,
                        size: 20,
                      ),
                    ),
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 50,
                        color: isCompleted ? AppColors.primary : AppColors.grey200,
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                // Step details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step['title'] as String,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                          color: isCompleted ? AppColors.textPrimary : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        step['subtitle'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          color: isCompleted ? AppColors.textSecondary : AppColors.textTertiary,
                        ),
                      ),
                      if (isCurrent && _getEstimatedTime() != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.access_time,
                                size: 14,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'ETA: ${_getEstimatedTime()}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (!isLast) const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  String? _getEstimatedTime() {
    final status = _delivery!.status.toLowerCase();

    // Estimate delivery time based on status
    switch (status) {
      case 'assigned':
        return '15-20 mins';
      case 'picked_up':
      case 'in_transit':
        if (_delivery!.distance != null) {
          // Estimate based on distance (assume 30 km/h average speed)
          final estimatedMinutes = (_delivery!.distance! / 30 * 60).ceil();
          if (estimatedMinutes < 60) {
            return '$estimatedMinutes mins';
          } else {
            return '${(estimatedMinutes / 60).ceil()} hrs';
          }
        }
        return '20-30 mins';
      default:
        return null;
    }
  }
}
