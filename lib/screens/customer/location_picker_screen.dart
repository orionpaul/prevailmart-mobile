import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../config/app_colors.dart';
import '../../services/location_service.dart';
import '../../models/address_model.dart';
import 'dart:io' show Platform;

/// Location Picker Screen - Select delivery address on map
class LocationPickerScreen extends StatefulWidget {
  final Address? initialAddress;

  const LocationPickerScreen({
    super.key,
    this.initialAddress,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  GoogleMapController? _mapController;
  LatLng _selectedLocation = const LatLng(0, 0);
  String _address = 'Fetching address...';
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _instructionsController = TextEditingController();
  final TextEditingController _manualAddressController = TextEditingController();
  String _selectedLabel = 'Home';
  bool _useManualAddress = false;

  @override
  void initState() {
    super.initState();
    // Delay initialization slightly on iOS to prevent crashes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeLocation();
      }
    });
  }

  Future<void> _initializeLocation() async {
    try {
      if (widget.initialAddress != null) {
        // Use provided address
        if (mounted) {
          setState(() {
            _selectedLocation = LatLng(
              widget.initialAddress!.latitude,
              widget.initialAddress!.longitude,
            );
            _address = widget.initialAddress!.fullAddress;
            _selectedLabel = widget.initialAddress!.label;
            _instructionsController.text = widget.initialAddress!.instructions ?? '';
            _isLoading = false;
          });
        }
        return;
      }

      // iOS-specific: Add delay to let permission dialog complete
      final isIOS = Platform.isIOS || defaultTargetPlatform == TargetPlatform.iOS;
      if (isIOS) {
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // Get current location with error handling
      try {
        // Request location with timeout
        final locationData = await locationService.getCurrentLocation()
            .timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            print('⏱️ Location request timeout');
            return null;
          },
        );

        if (locationData != null && locationData.latitude != null && locationData.longitude != null) {
          final latLng = LatLng(locationData.latitude!, locationData.longitude!);
          if (mounted) {
            setState(() {
              _selectedLocation = latLng;
            });
          }

          // Get address with timeout
          try {
            final address = await locationService.getAddressFromCoordinates(
              locationData.latitude!,
              locationData.longitude!,
            ).timeout(
              const Duration(seconds: 5),
              onTimeout: () {
                print('⏱️ Geocoding timeout');
                return 'Selected location';
              },
            );

            if (mounted) {
              setState(() {
                _address = address ?? 'Unknown location';
                _isLoading = false;
              });

              // Move camera to current location - wrap in try-catch for iOS
              try {
                await Future.delayed(const Duration(milliseconds: 300));
                _mapController?.animateCamera(
                  CameraUpdate.newLatLngZoom(latLng, 15),
                );
              } catch (cameraError) {
                print('Camera animation error (non-critical): $cameraError');
              }
            }
          } catch (addressError) {
            print('Error fetching address: $addressError');
            if (mounted) {
              setState(() {
                _address = 'Tap on map to select location';
                _isLoading = false;
              });
            }
          }
        } else {
          // Permission denied or location unavailable
          _setDefaultLocation('Tap on map to select your delivery location');
        }
      } catch (locationError) {
        print('Error getting location: $locationError');
        _setDefaultLocation('Location unavailable. Tap on map to select.');
      }
    } catch (e, stackTrace) {
      print('Error in _initializeLocation: $e');
      print('Stack trace: $stackTrace');
      _setDefaultLocation('Tap on map to select location');
    }
  }

  void _setDefaultLocation(String message) {
    if (mounted) {
      setState(() {
        _selectedLocation = const LatLng(6.5244, 3.3792); // Lagos, Nigeria
        _address = message;
        _isLoading = false;
      });
    }
  }

  Future<void> _onMapTap(LatLng position) async {
    if (!mounted) return;

    setState(() {
      _selectedLocation = position;
      _address = 'Fetching address...';
    });

    try {
      final address = await locationService.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (mounted) {
        setState(() {
          _address = address ?? 'Unknown location';
        });
      }
    } catch (e) {
      print('Error fetching address on map tap: $e');
      if (mounted) {
        setState(() {
          _address = 'Selected location';
        });
      }
    }
  }

  Future<void> _searchAddress() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final coordinates = await locationService.getCoordinatesFromAddress(query);

      if (coordinates != null && mounted) {
        setState(() {
          _selectedLocation = coordinates;
          _isLoading = false;
        });

        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(coordinates, 15),
        );

        // Update address
        await _onMapTap(coordinates);
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Address not found'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      print('Error searching address: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error searching address: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _confirmLocation() {
    // Use manual address if enabled and provided, otherwise use detected address
    String finalAddress = _address;
    if (_useManualAddress && _manualAddressController.text.trim().isNotEmpty) {
      finalAddress = _manualAddressController.text.trim();
    }

    final address = Address(
      label: _selectedLabel,
      fullAddress: finalAddress,
      latitude: _selectedLocation.latitude,
      longitude: _selectedLocation.longitude,
      instructions: _instructionsController.text.trim().isEmpty
          ? null
          : _instructionsController.text.trim(),
    );

    Navigator.pop(context, address);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Select Location',
          style: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedLocation,
              zoom: 15,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
            },
            onTap: _onMapTap,
            markers: {
              Marker(
                markerId: const MarkerId('selected'),
                position: _selectedLocation,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueBlue,
                ),
              ),
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
          ),

          // Search Bar
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search address...',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  prefixIcon: const Icon(Icons.search, color: AppColors.grey400),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send, color: AppColors.primary),
                    onPressed: _searchAddress,
                  ),
                ),
                onSubmitted: (_) => _searchAddress(),
              ),
            ),
          ),

          // Bottom Sheet with Address Details
          DraggableScrollableSheet(
            initialChildSize: 0.35,
            minChildSize: 0.35,
            maxChildSize: 0.7,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Drag Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: AppColors.grey300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Selected Address
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.location_on,
                            color: AppColors.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Delivery Location',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _address,
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

                    const SizedBox(height: 24),

                    // Address Label Selection
                    const Text(
                      'Save as',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildLabelChip('Home'),
                        const SizedBox(width: 12),
                        _buildLabelChip('Work'),
                        const SizedBox(width: 12),
                        _buildLabelChip('Other'),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Manual Address Toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Enter address manually',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Switch(
                          value: _useManualAddress,
                          onChanged: (value) {
                            setState(() {
                              _useManualAddress = value;
                              if (value && _manualAddressController.text.isEmpty) {
                                // Pre-fill with detected address
                                _manualAddressController.text = _address;
                              }
                            });
                          },
                          activeColor: AppColors.primary,
                        ),
                      ],
                    ),

                    if (_useManualAddress) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _manualAddressController,
                        decoration: InputDecoration(
                          hintText: 'Type your address here...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.grey300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.primary, width: 2),
                          ),
                          contentPadding: const EdgeInsets.all(16),
                          prefixIcon: const Icon(Icons.edit_location_alt, color: AppColors.primary),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You can edit the detected address or write your own',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.grey400,
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Delivery Instructions
                    const Text(
                      'Delivery Instructions (Optional)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _instructionsController,
                      decoration: InputDecoration(
                        hintText: 'e.g., Ring the doorbell, Leave at door...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.grey300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary, width: 2),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      maxLines: 2,
                    ),

                    const SizedBox(height: 24),

                    // Confirm Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _confirmLocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                              ),
                            )
                          : const Text(
                              'Confirm Location',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.white,
                              ),
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLabelChip(String label) {
    final isSelected = _selectedLabel == label;

    return GestureDetector(
      onTap: () => setState(() => _selectedLabel = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.grey100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.grey300,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              label == 'Home'
                  ? Icons.home
                  : label == 'Work'
                      ? Icons.work
                      : Icons.location_on,
              size: 16,
              color: isSelected ? AppColors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _instructionsController.dispose();
    _manualAddressController.dispose();
    _mapController?.dispose();
    super.dispose();
  }
}
