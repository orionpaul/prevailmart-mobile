import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import 'edit_profile_screen.dart';
import 'addresses_screen.dart';
import 'orders_screen.dart';
import 'notifications_settings_screen.dart';
import 'help_support_screen.dart';
import 'about_screen.dart';

/// Profile Screen - User account and settings
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: !auth.isAuthenticated
          ? _buildLoginPrompt(context)
          : CustomScrollView(
              slivers: [
                // Beautiful App Bar with gradient
                SliverAppBar(
                  expandedHeight: 240,
                  floating: false,
                  pinned: true,
                  backgroundColor: AppColors.primary,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                      ),
                      child: SafeArea(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 40),
                            // Avatar with glow effect
                            Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.white.withOpacity(0.3),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.white.withOpacity(0.3),
                                    width: 3,
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    Center(
                                      child: Icon(
                                        Icons.person,
                                        size: 55,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          gradient: AppColors.successGradient,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: AppColors.white,
                                            width: 2,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.verified,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Name with shine effect
                            Text(
                              user?.name ?? 'User',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: AppColors.white,
                                shadows: [
                                  Shadow(
                                    color: Colors.black26,
                                    offset: Offset(0, 2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Email
                            Text(
                              user?.email ?? '',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.white.withOpacity(0.95),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Role Badge with icon
                            if (user?.role != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.white.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppColors.white.withOpacity(0.3),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      user!.role == 'driver'
                                          ? Icons.local_shipping_rounded
                                          : Icons.shopping_bag_rounded,
                                      size: 16,
                                      color: AppColors.white,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      user.role.toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.white,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Content
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      children: [
                        _buildMenuItem(
                          icon: Icons.person_outline,
                          title: 'Edit Profile',
                          subtitle: 'Update your personal information',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const EditProfileScreen(),
                              ),
                            );
                          },
                        ),
                        _buildMenuItem(
                          icon: Icons.location_on_outlined,
                          title: 'Delivery Addresses',
                          subtitle: 'Manage your delivery locations',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AddressesScreen(),
                              ),
                            );
                          },
                        ),
                        _buildMenuItem(
                          icon: Icons.receipt_long_outlined,
                          title: 'Order History',
                          subtitle: 'View your past orders',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const OrdersScreen(),
                              ),
                            );
                          },
                        ),
                        _buildMenuItem(
                          icon: Icons.notifications_outlined,
                          title: 'Notifications',
                          subtitle: 'Manage notification preferences',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const NotificationsSettingsScreen(),
                              ),
                            );
                          },
                        ),
                        _buildMenuItem(
                          icon: Icons.help_outline,
                          title: 'Help & Support',
                          subtitle: 'Get help with your orders',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const HelpSupportScreen(),
                              ),
                            );
                          },
                        ),
                        _buildMenuItem(
                          icon: Icons.info_outline,
                          title: 'About',
                          subtitle: 'App version and information',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AboutScreen(),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 16),

                        // Logout Button
                        _buildLogoutButton(context, auth),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildLoginPrompt(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_circle_outlined,
              size: 100,
              color: AppColors.grey400,
            ),
            const SizedBox(height: 24),
            const Text(
              'Login Required',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please login to view your profile',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LoginScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Login Now',
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

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 8,
        ),
        leading: Container(
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
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppColors.grey400,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, AuthProvider auth) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.error.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 8,
        ),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.logout,
            color: AppColors.error,
            size: 24,
          ),
        ),
        title: const Text(
          'Logout',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.error,
          ),
        ),
        onTap: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text('Logout'),
              content: const Text('Are you sure you want to logout?'),
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
                  child: const Text('Logout'),
                ),
              ],
            ),
          );

          if (confirmed == true && context.mounted) {
            await auth.logout();
            if (context.mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            }
          }
        },
      ),
    );
  }
}
