import 'dart:async';
import 'dart:math' show cos, sqrt, asin;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../config/app_colors.dart';
import '../models/order_model.dart';

/// Delivery Map Widget - Shows real-time driver location and delivery destination
class DeliveryMapWidget extends StatefulWidget {
  final DriverLocation driverLocation;
  final DriverLocation deliveryLocation;
  final String orderStatus;

  const DeliveryMapWidget({
    super.key,
    required this.driverLocation,
    required this.deliveryLocation,
    required this.orderStatus,
  });

  @override
  State<DeliveryMapWidget> createState() => _DeliveryMapWidgetState();
}

class _DeliveryMapWidgetState extends State<DeliveryMapWidget> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _setupMapElements();
  }

  @override
  void didUpdateWidget(DeliveryMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.driverLocation.latitude != widget.driverLocation.latitude ||
        oldWidget.driverLocation.longitude != widget.driverLocation.longitude) {
      _setupMapElements();
      _animateToShowBothLocations();
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _setupMapElements() {
    _markers = {
      // Driver marker
      Marker(
        markerId: const MarkerId('driver'),
        position: LatLng(
          widget.driverLocation.latitude,
          widget.driverLocation.longitude,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(
          title: 'Driver Location',
          snippet: 'Your order is on the way',
        ),
      ),
      // Delivery destination marker
      Marker(
        markerId: const MarkerId('delivery'),
        position: LatLng(
          widget.deliveryLocation.latitude,
          widget.deliveryLocation.longitude,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(
          title: 'Delivery Location',
          snippet: 'Your order will be delivered here',
        ),
      ),
    };

    // Draw line between driver and delivery location
    _polylines = {
      Polyline(
        polylineId: const PolylineId('route'),
        points: [
          LatLng(
            widget.driverLocation.latitude,
            widget.driverLocation.longitude,
          ),
          LatLng(
            widget.deliveryLocation.latitude,
            widget.deliveryLocation.longitude,
          ),
        ],
        color: AppColors.primary,
        width: 4,
        patterns: [PatternItem.dash(20), PatternItem.gap(10)],
      ),
    };

    if (mounted) {
      setState(() {});
    }
  }

  void _animateToShowBothLocations() {
    if (_mapController == null) return;

    // Calculate bounds to show both markers
    final bounds = _calculateBounds(
      widget.driverLocation,
      widget.deliveryLocation,
    );

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100),
    );
  }

  LatLngBounds _calculateBounds(
    DriverLocation loc1,
    DriverLocation loc2,
  ) {
    final southwest = LatLng(
      loc1.latitude < loc2.latitude ? loc1.latitude : loc2.latitude,
      loc1.longitude < loc2.longitude ? loc1.longitude : loc2.longitude,
    );
    final northeast = LatLng(
      loc1.latitude > loc2.latitude ? loc1.latitude : loc2.latitude,
      loc1.longitude > loc2.longitude ? loc1.longitude : loc2.longitude,
    );

    return LatLngBounds(southwest: southwest, northeast: northeast);
  }

  double _calculateDistance(DriverLocation loc1, DriverLocation loc2) {
    // Haversine formula for calculating distance between two coordinates
    const double earthRadius = 6371; // Earth radius in kilometers

    final double dLat = _toRadians(loc2.latitude - loc1.latitude);
    final double dLon = _toRadians(loc2.longitude - loc1.longitude);

    final double a = (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_toRadians(loc1.latitude)) *
            cos(_toRadians(loc2.latitude)) *
            (sin(dLon / 2) * sin(dLon / 2));

    final double c = 2 * asin(sqrt(a));

    return earthRadius * c; // Distance in kilometers
  }

  double _toRadians(double degrees) {
    return degrees * (3.14159265359 / 180.0);
  }

  double sin(double radians) {
    // Using Taylor series approximation for sine
    double result = radians;
    double term = radians;
    for (int i = 1; i <= 10; i++) {
      term *= -radians * radians / ((2 * i) * (2 * i + 1));
      result += term;
    }
    return result;
  }

  int _calculateETA(double distance) {
    // Assume average speed of 30 km/h
    const double averageSpeed = 30.0;
    return (distance / averageSpeed * 60).round(); // Return minutes
  }

  @override
  Widget build(BuildContext context) {
    final distance = _calculateDistance(
      widget.driverLocation,
      widget.deliveryLocation,
    );
    final eta = _calculateETA(distance);

    return Container(
      height: 400,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Google Map
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  widget.driverLocation.latitude,
                  widget.driverLocation.longitude,
                ),
                zoom: 14,
              ),
              markers: _markers,
              polylines: _polylines,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              onMapCreated: (controller) {
                _mapController = controller;
                Future.delayed(const Duration(milliseconds: 500), () {
                  _animateToShowBothLocations();
                });
              },
            ),

            // Distance and ETA Card
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoItem(
                        icon: Icons.route,
                        label: 'Distance',
                        value: '${distance.toStringAsFixed(1)} km',
                        color: AppColors.primary,
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: AppColors.grey300,
                      ),
                      _buildInfoItem(
                        icon: Icons.access_time,
                        label: 'ETA',
                        value: '$eta min',
                        color: AppColors.success,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Zoom Controls
            Positioned(
              right: 16,
              bottom: 100,
              child: Column(
                children: [
                  FloatingActionButton(
                    mini: true,
                    backgroundColor: AppColors.white,
                    onPressed: () {
                      _mapController?.animateCamera(
                        CameraUpdate.zoomIn(),
                      );
                    },
                    child: const Icon(Icons.add, color: AppColors.primary),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton(
                    mini: true,
                    backgroundColor: AppColors.white,
                    onPressed: () {
                      _mapController?.animateCamera(
                        CameraUpdate.zoomOut(),
                      );
                    },
                    child: const Icon(Icons.remove, color: AppColors.primary),
                  ),
                ],
              ),
            ),

            // Center on Route Button
            Positioned(
              right: 16,
              bottom: 24,
              child: FloatingActionButton(
                mini: true,
                backgroundColor: AppColors.primary,
                onPressed: _animateToShowBothLocations,
                child: const Icon(Icons.my_location, color: AppColors.white),
              ),
            ),

            // Legend
            Positioned(
              bottom: 16,
              left: 16,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildLegendItem(
                        color: Colors.blue,
                        label: 'Driver',
                      ),
                      const SizedBox(height: 6),
                      _buildLegendItem(
                        color: Colors.red,
                        label: 'Delivery',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
