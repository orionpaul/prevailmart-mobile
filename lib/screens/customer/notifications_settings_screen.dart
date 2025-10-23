import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../services/storage_service.dart';

/// Notifications Settings Screen
class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() => _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState extends State<NotificationsSettingsScreen> {
  bool _orderUpdates = true;
  bool _promotions = true;
  bool _deliveryUpdates = true;
  bool _newArrivals = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await storageService.getJson('notification_settings');
    if (settings != null && mounted) {
      setState(() {
        _orderUpdates = settings['orderUpdates'] ?? true;
        _promotions = settings['promotions'] ?? true;
        _deliveryUpdates = settings['deliveryUpdates'] ?? true;
        _newArrivals = settings['newArrivals'] ?? false;
      });
    }
  }

  Future<void> _saveSettings() async {
    await storageService.saveJson('notification_settings', {
      'orderUpdates': _orderUpdates,
      'promotions': _promotions,
      'deliveryUpdates': _deliveryUpdates,
      'newArrivals': _newArrivals,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification settings saved'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
          'Notifications',
          style: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Push Notifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          _buildSettingTile(
            icon: Icons.shopping_bag_outlined,
            title: 'Order Updates',
            subtitle: 'Get notified about your order status',
            value: _orderUpdates,
            onChanged: (val) {
              setState(() => _orderUpdates = val);
              _saveSettings();
            },
          ),

          _buildSettingTile(
            icon: Icons.local_shipping_outlined,
            title: 'Delivery Updates',
            subtitle: 'Real-time delivery tracking updates',
            value: _deliveryUpdates,
            onChanged: (val) {
              setState(() => _deliveryUpdates = val);
              _saveSettings();
            },
          ),

          const SizedBox(height: 24),

          const Text(
            'Marketing',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          _buildSettingTile(
            icon: Icons.local_offer_outlined,
            title: 'Promotions',
            subtitle: 'Deals, offers and discounts',
            value: _promotions,
            onChanged: (val) {
              setState(() => _promotions = val);
              _saveSettings();
            },
          ),

          _buildSettingTile(
            icon: Icons.new_releases_outlined,
            title: 'New Arrivals',
            subtitle: 'Notifications about new products',
            value: _newArrivals,
            onChanged: (val) {
              setState(() => _newArrivals = val);
              _saveSettings();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        secondary: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
