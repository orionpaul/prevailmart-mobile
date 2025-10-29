import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../config/api_config.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../models/address_model.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import 'orders_screen.dart';
import 'addresses_screen.dart';
import 'customer_main_screen.dart';

/// Checkout Screen - Place order
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();

  String _paymentMethod = 'cash';
  bool _isPlacingOrder = false;

  // Address management
  List<Address> _savedAddresses = [];
  Address? _selectedAddress;

  @override
  void initState() {
    super.initState();
    _initializeCheckout();
  }

  /// Initialize checkout with user data and saved addresses
  Future<void> _initializeCheckout() async {
    final auth = context.read<AuthProvider>();

    // Load basic user info
    if (auth.isAuthenticated && auth.user != null) {
      _nameController.text = auth.user!.name;
      _emailController.text = auth.user!.email;
      _phoneController.text = auth.user!.phone ?? '';
    }

    // Load saved addresses
    await _loadSavedAddresses();

    // Find and use default address
    final defaultAddress = _savedAddresses.firstWhere(
      (addr) => addr.isDefault,
      orElse: () => _savedAddresses.isNotEmpty ? _savedAddresses.first : null as Address,
    );

    if (defaultAddress != null) {
      _selectAddress(defaultAddress);
    } else if (auth.isAuthenticated && auth.user?.address != null && auth.user!.address!.isNotEmpty) {
      // Fallback to user's single address field if no saved addresses
      _addressController.text = auth.user!.address!;
    }
  }

  /// Load saved addresses from storage
  Future<void> _loadSavedAddresses() async {
    try {
      final data = await storageService.getJson('saved_addresses');
      if (data != null && data['addresses'] != null) {
        final addressesList = data['addresses'] as List;
        setState(() {
          _savedAddresses = addressesList
              .map((addr) => Address.fromJson(addr as Map<String, dynamic>))
              .toList();
        });
        print('✅ Loaded ${_savedAddresses.length} saved addresses');
      }
    } catch (e) {
      print('❌ Error loading saved addresses: $e');
    }
  }

  /// Select an address and autofill fields
  void _selectAddress(Address address) {
    setState(() {
      _selectedAddress = address;
      _addressController.text = address.fullAddress;
    });
    print('📍 Selected address: ${address.label} - ${address.fullAddress}');
  }

  /// Show address selector bottom sheet
  void _showAddressSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Address',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._savedAddresses.map((address) => _buildAddressOption(address)),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _navigateToAddresses();
              },
              icon: const Icon(Icons.add_location_alt),
              label: const Text('Add New Address'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build address option for selector
  Widget _buildAddressOption(Address address) {
    final isSelected = _selectedAddress?.id == address.id;

    return GestureDetector(
      onTap: () {
        _selectAddress(address);
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              address.label == 'Home'
                  ? Icons.home
                  : address.label == 'Work'
                      ? Icons.work
                      : Icons.location_on,
              color: isSelected ? AppColors.primary : AppColors.grey400,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        address.label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                      ),
                      if (address.isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Default',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    address.fullAddress,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primary,
              ),
          ],
        ),
      ),
    );
  }

  /// Navigate to addresses management screen
  Future<void> _navigateToAddresses() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddressesScreen()),
    );

    // Reload addresses if any changes were made
    if (result == true) {
      await _loadSavedAddresses();

      // Re-select default address if current selection was removed
      if (_selectedAddress != null &&
          !_savedAddresses.any((addr) => addr.id == _selectedAddress!.id)) {
        final defaultAddress = _savedAddresses.firstWhere(
          (addr) => addr.isDefault,
          orElse: () => _savedAddresses.isNotEmpty
              ? _savedAddresses.first
              : null as Address,
        );
        if (defaultAddress != null) {
          _selectAddress(defaultAddress);
        } else {
          setState(() {
            _selectedAddress = null;
            _addressController.clear();
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isPlacingOrder = true);

    try {
      final cart = context.read<CartProvider>();
      final auth = context.read<AuthProvider>();

      // Use selected address if available, otherwise parse text input
      final address = _addressController.text.trim();
      Map<String, dynamic> shippingAddress;

      if (_selectedAddress != null) {
        // Use saved address with proper coordinates
        shippingAddress = {
          'street': _selectedAddress!.street ?? _selectedAddress!.fullAddress,
          'city': _selectedAddress!.city ?? 'Harare',
          'state': _selectedAddress!.state ?? 'Harare Province',
          'zipCode': _selectedAddress!.zipCode ?? '00263',
          'country': _selectedAddress!.country ?? 'Zimbabwe',
          'coordinates': {
            'latitude': _selectedAddress!.latitude,
            'longitude': _selectedAddress!.longitude,
          }
        };
      } else {
        // Parse address from text input - fallback for manual entry
        final addressParts = address.split(',').map((e) => e.trim()).toList();
        shippingAddress = {
          'street': addressParts.isNotEmpty ? addressParts[0] : address,
          'city': addressParts.length > 1 ? addressParts[1] : 'Harare',
          'state': addressParts.length > 2 ? addressParts[2] : 'Harare Province',
          'zipCode': '00263',
          'country': 'Zimbabwe',
          'coordinates': {
            'latitude': -17.8252, // Default Harare coordinates
            'longitude': 31.0335,
          }
        };
      }

      // Create order data
      final orderData = {
        'shippingAddress': shippingAddress,
        'paymentMethod': _paymentMethod == 'cash' ? 'cash_on_delivery' : 'credit_card',
        'customerPhone': _phoneController.text.trim(),
        'customerName': auth.isAuthenticated ? auth.user?.name : _nameController.text.trim(),
        'notes': _notesController.text.trim(),
        'shippingCost': 5.0,
      };

      print('📦 Placing order with data: $orderData');

      final response = await apiService.post(
        ApiConfig.orders,
        data: orderData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Clear cart after successful order
        await cart.clearCart();

        if (mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order placed successfully!'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );

          // Pop back to home and switch to Orders tab (index 2)
          Navigator.of(context).popUntil((route) => route.isFirst);
          CustomerMainScreen.switchTab(context, 2);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to place order: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPlacingOrder = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'Checkout',
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
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Contact Information
                    _buildSectionTitle('Contact Information'),
                    const SizedBox(height: 12),

                    CustomTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      hint: 'Enter your full name',
                      prefixIcon: Icons.person_outline,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    CustomTextField(
                      controller: _emailController,
                      label: 'Email',
                      hint: 'Enter your email',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // Delivery Information
                    _buildSectionTitle('Delivery Information'),
                    const SizedBox(height: 12),

                    // Saved Addresses Section
                    if (_savedAddresses.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedAddress != null
                                ? AppColors.primary.withOpacity(0.3)
                                : AppColors.border,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.bookmark,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _selectedAddress != null
                                      ? 'Using saved address: ${_selectedAddress!.label}'
                                      : 'Select a saved address',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _showAddressSelector,
                                    icon: const Icon(Icons.location_searching, size: 18),
                                    label: const Text('Change Address'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.primary,
                                      side: const BorderSide(color: AppColors.primary),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton(
                                  onPressed: _navigateToAddresses,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                    side: const BorderSide(color: AppColors.primary),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                  ),
                                  child: const Icon(Icons.edit_location, size: 18),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    CustomTextField(
                      controller: _addressController,
                      label: 'Delivery Address',
                      hint: 'Enter your delivery address',
                      prefixIcon: Icons.location_on_outlined,
                      maxLines: 2,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter delivery address';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    CustomTextField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      hint: 'Enter your phone number',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter phone number';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // Payment Method
                    _buildSectionTitle('Payment Method'),
                    const SizedBox(height: 12),

                    _buildPaymentOption(
                      'cash',
                      'Cash on Delivery',
                      Icons.money,
                    ),

                    _buildPaymentOption(
                      'card',
                      'Credit/Debit Card',
                      Icons.credit_card,
                    ),

                    _buildPaymentOption(
                      'mobile',
                      'Mobile Money',
                      Icons.phone_android,
                    ),

                    const SizedBox(height: 24),

                    // Order Notes
                    _buildSectionTitle('Order Notes (Optional)'),
                    const SizedBox(height: 12),

                    CustomTextField(
                      controller: _notesController,
                      hint: 'Add any special instructions...',
                      prefixIcon: Icons.note_outlined,
                      maxLines: 3,
                    ),

                    const SizedBox(height: 24),

                    // Order Summary
                    _buildSectionTitle('Order Summary'),
                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          _buildSummaryRow(
                            'Items',
                            '${cart.itemCount} items',
                          ),
                          const SizedBox(height: 8),
                          _buildSummaryRow(
                            'Subtotal',
                            '\$${cart.total.toStringAsFixed(2)}',
                          ),
                          const SizedBox(height: 8),
                          _buildSummaryRow(
                            'Delivery Fee',
                            '\$5.00',
                          ),
                          const Divider(height: 24),
                          _buildSummaryRow(
                            'Total',
                            '\$${(cart.total + 5.0).toStringAsFixed(2)}',
                            isBold: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Place Order Button
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
                  text: 'Place Order',
                  onPressed: _placeOrder,
                  isLoading: _isPlacingOrder,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildPaymentOption(String value, String label, IconData icon) {
    final isSelected = _paymentMethod == value;

    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.grey400,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color:
                      isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 18 : 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 18 : 16,
            fontWeight: FontWeight.w600,
            color: isBold ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
