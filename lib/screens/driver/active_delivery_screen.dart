import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../config/app_colors.dart';
import '../../models/delivery_model.dart';
import '../../providers/delivery_provider.dart';
import '../../services/location_service.dart';
import '../../services/realtime_delivery_service.dart';
import '../../widgets/common/custom_button.dart';

/// Active Delivery Screen - View delivery details with live map tracking
class ActiveDeliveryScreen extends StatefulWidget {
  final Delivery delivery;

  const ActiveDeliveryScreen({
    super.key,
    required this.delivery,
  });

  @override
  State<ActiveDeliveryScreen> createState() => _ActiveDeliveryScreenState();
}

class _ActiveDeliveryScreenState extends State<ActiveDeliveryScreen> {
  GoogleMapController? _mapController;
  Timer? _locationTimer;
  LatLng? _driverLocation;
  LatLng? _customerLocation;
  bool _isMapExpanded = true;

  @override
  void initState() {
    super.initState();
    _initializeMap();
    _startRealtimeTracking();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _mapController?.dispose();
    realtimeDeliveryService.stopTracking();
    super.dispose();
  }

  Future<void> _initializeMap() async {
    try {
      // Get driver's current location
      final locationData = await locationService.getCurrentLocation();
      if (locationData != null && locationData.latitude != null && locationData.longitude != null) {
        if (mounted) {
          setState(() {
            _driverLocation = LatLng(locationData.latitude!, locationData.longitude!);
          });
        }
      }

      // Get customer location from delivery address
      final deliveryAddress = widget.delivery.order.deliveryAddress;
      if (deliveryAddress != null) {
        final coords = await locationService.getCoordinatesFromAddress(deliveryAddress);
        if (coords != null && mounted) {
          setState(() {
            _customerLocation = coords;
          });

          // Move camera to show both locations
          if (_driverLocation != null && _customerLocation != null) {
            _fitBounds();
          }
        }
      }
    } catch (e) {
      print('Error initializing map: $e');
    }
  }

  void _fitBounds() {
    if (_mapController == null || _driverLocation == null || _customerLocation == null) return;

    final bounds = LatLngBounds(
      southwest: LatLng(
        _driverLocation!.latitude < _customerLocation!.latitude
            ? _driverLocation!.latitude
            : _customerLocation!.latitude,
        _driverLocation!.longitude < _customerLocation!.longitude
            ? _driverLocation!.longitude
            : _customerLocation!.longitude,
      ),
      northeast: LatLng(
        _driverLocation!.latitude > _customerLocation!.latitude
            ? _driverLocation!.latitude
            : _customerLocation!.latitude,
        _driverLocation!.longitude > _customerLocation!.longitude
            ? _driverLocation!.longitude
            : _customerLocation!.longitude,
      ),
    );

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100),
    );
  }

  void _startRealtimeTracking() async {
    // Initialize the real-time delivery service with provider
    final deliveryProvider = context.read<DeliveryProvider>();
    realtimeDeliveryService.init(deliveryProvider);

    // Start real-time tracking for this delivery
    await realtimeDeliveryService.startTracking(widget.delivery.id);

    // Update map with location changes (still use timer for UI updates)
    _locationTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      final locationData = await locationService.getCurrentLocation();
      if (locationData != null && locationData.latitude != null && locationData.longitude != null) {
        if (mounted) {
          setState(() {
            _driverLocation = LatLng(locationData.latitude!, locationData.longitude!);
          });
        }
      }
    });
  }

  Future<void> _callCustomer() async {
    final phone = widget.delivery.customerPhone ?? widget.delivery.order.deliveryAddress;
    if (phone != null) {
      final url = Uri.parse('tel:$phone');
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      }
    }
  }

  Future<void> _openMaps() async {
    final address = widget.delivery.order.deliveryAddress ?? '';
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.secondary,
        elevation: 0,
        title: const Text(
          'Active Delivery',
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
            icon: Icon(
              _isMapExpanded ? Icons.expand_less : Icons.expand_more,
              color: AppColors.white,
            ),
            onPressed: () {
              setState(() {
                _isMapExpanded = !_isMapExpanded;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Live Map Section
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _isMapExpanded ? 300 : 0,
            child: _driverLocation != null
                ? GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _driverLocation!,
                      zoom: 14,
                    ),
                    onMapCreated: (controller) {
                      _mapController = controller;
                      if (_customerLocation != null) {
                        _fitBounds();
                      }
                    },
                    markers: {
                      if (_driverLocation != null)
                        Marker(
                          markerId: const MarkerId('driver'),
                          position: _driverLocation!,
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueAzure,
                          ),
                          infoWindow: const InfoWindow(title: 'Your Location'),
                        ),
                      if (_customerLocation != null)
                        Marker(
                          markerId: const MarkerId('customer'),
                          position: _customerLocation!,
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueRed,
                          ),
                          infoWindow: const InfoWindow(title: 'Delivery Address'),
                        ),
                    },
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    zoomControlsEnabled: false,
                  )
                : Container(
                    color: AppColors.grey100,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.secondary, AppColors.secondaryDark],
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          widget.delivery.canComplete
                              ? Icons.local_shipping
                              : Icons.check_circle_outline,
                          color: AppColors.white,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.delivery.statusDisplay,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Order #${widget.delivery.order.id.substring(widget.delivery.order.id.length - 6).toUpperCase()}',
                          style: TextStyle(
                            color: AppColors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Quick Actions
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.phone,
                            label: 'Call',
                            color: AppColors.primary,
                            onTap: _callCustomer,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.navigation,
                            label: 'Navigate',
                            color: AppColors.secondary,
                            onTap: _openMaps,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Delivery Details
                  _buildSection(
                    title: 'Delivery Address',
                    child: _buildInfoCard(
                      icon: Icons.location_on,
                      iconColor: AppColors.error,
                      title: 'Delivery Location',
                      subtitle: widget.delivery.order.deliveryAddress ?? 'No address',
                    ),
                  ),

                  _buildSection(
                    title: 'Order Items',
                    child: Column(
                      children: [
                        ...widget.delivery.order.items.map((item) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.grey100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.shopping_bag_outlined,
                                    color: AppColors.grey400,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
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
                                      Text(
                                        'Qty: ${item.quantity}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
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
                      ],
                    ),
                  ),

                  _buildSection(
                    title: 'Payment & Earnings',
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          _buildPaymentRow(
                            'Order Total',
                            '\$${widget.delivery.order.total.toStringAsFixed(2)}',
                          ),
                          const SizedBox(height: 8),
                          _buildPaymentRow(
                            'Payment Method',
                            widget.delivery.order.paymentMethod ?? 'Cash',
                          ),
                          const Divider(height: 24),
                          _buildPaymentRow(
                            'Your Earnings',
                            '\$${widget.delivery.earnings.toStringAsFixed(2)}',
                            isEarnings: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Complete Delivery Button
          if (widget.delivery.canComplete)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: CustomButton(
                  text: 'Complete Delivery',
                  icon: Icons.check_circle,
                  color: AppColors.success,
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Complete Delivery'),
                        content: const Text(
                          'Have you successfully delivered the order to the customer?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Not Yet'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                            ),
                            child: const Text('Complete'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true && context.mounted) {
                      final deliveryProvider = context.read<DeliveryProvider>();
                      final success = await deliveryProvider.completeDelivery(
                        widget.delivery.id,
                      );

                      if (success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Delivery completed successfully!'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                        Navigator.of(context).pop();
                      }
                    }
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
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

  Widget _buildPaymentRow(String label, String value, {bool isEarnings = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isEarnings ? 16 : 14,
            fontWeight: isEarnings ? FontWeight.bold : FontWeight.normal,
            color: isEarnings ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isEarnings ? 18 : 14,
            fontWeight: FontWeight.w600,
            color: isEarnings ? AppColors.success : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
