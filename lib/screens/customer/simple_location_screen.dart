import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../models/address_model.dart';
import '../../services/storage_service.dart';

/// Simple Location Screen - Clean address selection
class SimpleLocationScreen extends StatefulWidget {
  const SimpleLocationScreen({super.key});

  @override
  State<SimpleLocationScreen> createState() => _SimpleLocationScreenState();
}

class _SimpleLocationScreenState extends State<SimpleLocationScreen> {
  List<Address> _savedAddresses = [];
  Address? _selectedAddress;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedAddresses();
  }

  Future<void> _loadSavedAddresses() async {
    try {
      final data = await storageService.getJson('saved_addresses');
      if (data != null && data['addresses'] != null) {
        final addressesList = data['addresses'] as List;
        setState(() {
          _savedAddresses = addressesList
              .map((addr) => Address.fromJson(addr as Map<String, dynamic>))
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('❌ Error loading addresses: $e');
      setState(() => _isLoading = false);
    }
  }

  void _selectAddress(Address address) {
    setState(() => _selectedAddress = address);
    Navigator.pop(context, address);
  }

  void _showAddAddressDialog() {
    final labelController = TextEditingController();
    final addressController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add New Address',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Label
              const Text(
                'Label',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildLabelChip('Home', Icons.home_rounded, labelController),
                  const SizedBox(width: 8),
                  _buildLabelChip('Work', Icons.work_rounded, labelController),
                  const SizedBox(width: 8),
                  _buildLabelChip('Other', Icons.location_on_rounded, labelController),
                ],
              ),
              const SizedBox(height: 20),

              // Address
              const Text(
                'Full Address',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: addressController,
                decoration: InputDecoration(
                  hintText: 'Enter your full address',
                  hintStyle: TextStyle(color: AppColors.grey400),
                  filled: true,
                  fillColor: AppColors.grey50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    if (labelController.text.isEmpty || addressController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill all fields')),
                      );
                      return;
                    }

                    final newAddress = Address(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      label: labelController.text,
                      fullAddress: addressController.text,
                      latitude: 0,
                      longitude: 0,
                      isDefault: _savedAddresses.isEmpty,
                    );

                    _savedAddresses.add(newAddress);
                    _saveAddresses();
                    Navigator.pop(context);
                    setState(() {});
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.white,
                    foregroundColor: AppColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                  child: const Text(
                    'Save Address',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabelChip(String label, IconData icon, TextEditingController controller) {
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.text = label,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.grey50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: controller.text == label ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: controller.text == label ? AppColors.primary : AppColors.grey400,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: controller.text == label ? AppColors.primary : AppColors.grey600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveAddresses() async {
    try {
      final data = {
        'addresses': _savedAddresses.map((a) => a.toJson()).toList(),
      };
      await storageService.saveJson('saved_addresses', data);
    } catch (e) {
      print('❌ Error saving addresses: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        ),
        title: const Text(
          'Select Location',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                // Add Address Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GestureDetector(
                    onTap: _showAddAddressDialog,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.add_location_alt_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Add New Address',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Saved Addresses
                if (_savedAddresses.isEmpty)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.location_off_rounded,
                            size: 80,
                            color: AppColors.grey300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No saved addresses',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.grey600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add your first address to get started',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.grey500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _savedAddresses.length,
                      itemBuilder: (context, index) {
                        final address = _savedAddresses[index];
                        return _buildAddressCard(address);
                      },
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildAddressCard(Address address) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectAddress(address),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    address.label == 'Home'
                        ? Icons.home_rounded
                        : address.label == 'Work'
                            ? Icons.work_rounded
                            : Icons.location_on_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),

                // Address Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        address.label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        address.fullAddress,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.grey600,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Arrow
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.grey400,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
