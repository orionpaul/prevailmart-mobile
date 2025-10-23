import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../models/address_model.dart';
import '../../services/storage_service.dart';
import 'location_picker_screen.dart';

/// Addresses Screen - Manage delivery addresses
class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  List<Address> _addresses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() => _isLoading = true);

    try {
      final addressesData = await storageService.getJson('saved_addresses');
      if (addressesData != null) {
        final List<dynamic> addressList = addressesData['addresses'] as List? ?? [];
        setState(() {
          _addresses = addressList
              .map((a) => Address.fromJson(a as Map<String, dynamic>))
              .toList();
        });
      }
    } catch (e) {
      print('❌ Error loading addresses: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAddresses() async {
    try {
      final data = _addresses.map((a) => a.toJson()).toList();
      await storageService.saveJson('saved_addresses', {'addresses': data});
    } catch (e) {
      print('❌ Error saving addresses: $e');
    }
  }

  Future<void> _addAddress() async {
    final Address? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const LocationPickerScreen(),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _addresses.add(result);
      });
      await _saveAddresses();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Address added successfully'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _editAddress(int index) async {
    final Address? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialAddress: _addresses[index],
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _addresses[index] = result;
      });
      await _saveAddresses();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Address updated successfully'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _deleteAddress(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Delete Address'),
        content: const Text('Are you sure you want to delete this address?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() {
        _addresses.removeAt(index);
      });
      await _saveAddresses();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Address deleted'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _setDefault(int index) async {
    setState(() {
      for (int i = 0; i < _addresses.length; i++) {
        _addresses[i] = _addresses[i].copyWith(isDefault: i == index);
      }
    });
    await _saveAddresses();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Default address updated'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Delivery Addresses',
          style: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _addresses.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _addresses.length,
                  itemBuilder: (context, index) {
                    return _buildAddressCard(_addresses[index], index);
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addAddress,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: AppColors.white),
        label: const Text(
          'Add Address',
          style: TextStyle(color: AppColors.white),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off_outlined,
              size: 80,
              color: AppColors.grey400,
            ),
            const SizedBox(height: 24),
            const Text(
              'No Saved Addresses',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Add your delivery addresses for faster checkout',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _addAddress,
              icon: const Icon(Icons.add, color: AppColors.white),
              label: const Text(
                'Add Address',
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
    );
  }

  Widget _buildAddressCard(Address address, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: address.isDefault ? AppColors.primary : AppColors.grey200,
          width: address.isDefault ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: address.isDefault
                        ? AppColors.primary
                        : AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    address.label == 'Home'
                        ? Icons.home
                        : address.label == 'Work'
                            ? Icons.work
                            : Icons.location_on,
                    color: address.isDefault ? AppColors.white : AppColors.primary,
                    size: 24,
                  ),
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
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (address.isDefault) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'DEFAULT',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        address.fullAddress,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (address.instructions != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Note: ${address.instructions}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary.withOpacity(0.7),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Actions
          Divider(height: 1, color: AppColors.grey200),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: () => _editAddress(index),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _deleteAddress(index),
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.error,
                  ),
                ),
                if (!address.isDefault)
                  TextButton.icon(
                    onPressed: () => _setDefault(index),
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: const Text('Set Default'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.success,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
