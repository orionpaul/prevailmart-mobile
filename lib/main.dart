import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/app_colors.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/delivery_provider.dart';
import 'services/storage_service.dart';
import 'screens/customer/customer_main_screen.dart';
import 'screens/driver/driver_main_screen.dart';

/// PrevailMart Mobile App - Customer & Driver
/// Admin/SuperAdmin features are on the website dashboard only
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize secure storage
  await storageService.initialize();

  runApp(const PrevailMartApp());
}

class PrevailMartApp extends StatelessWidget {
  const PrevailMartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => DeliveryProvider()),
      ],
      child: MaterialApp(
        title: 'PrevailMart - Shop & Deliver',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            primary: AppColors.primary,
            secondary: AppColors.secondary,
          ),
          scaffoldBackgroundColor: AppColors.background,
        ),
        home: const AppRoot(),
      ),
    );
  }
}

/// Root widget that handles role-based routing
/// GUEST BROWSING: Users can browse store without login!
/// GUEST CART: Guests can add items to cart (stored locally)
/// Authentication required for: Checkout, orders
/// NOTE: Admin/SuperAdmin access is on website dashboard only
class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        // If not logged in, allow guest browsing of customer store
        if (!auth.isAuthenticated) {
          print('👤 Guest user - browsing store');
          return const CustomerMainScreen(); // Guests can browse the store
        }

        // Route based on user role
        final userRole = auth.user?.role;
        print('🎯 User logged in with role: $userRole');

        // Admin/SuperAdmin should use website dashboard, not mobile app
        if (userRole == 'admin' || userRole == 'superadmin') {
          print('⚠️ Admin/SuperAdmin detected - showing customer view');
          print('ℹ️ Please use website dashboard for admin features');
          return const CustomerMainScreen(); // Admins can browse on mobile
        } else if (userRole == 'driver') {
          print('📦 Routing to DRIVER interface');
          return const DriverMainScreen(); // Driver sees delivery interface
        } else {
          print('🛍️ Routing to CUSTOMER interface');
          return const CustomerMainScreen(); // Customer sees shopping interface
        }
      },
    );
  }
}
