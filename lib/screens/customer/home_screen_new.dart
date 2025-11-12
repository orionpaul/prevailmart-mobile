import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:badges/badges.dart' as badges;
import '../../config/app_colors.dart';
import '../../config/api_config.dart';
import '../../models/product_model.dart';
import '../../services/api_service.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/customer/product_card.dart';
import '../../widgets/customer/product_card_shimmer.dart';
import '../../widgets/common/promotional_banner_carousel.dart';
import 'cart_screen.dart';
import 'products_screen.dart';
import 'location_picker_screen.dart';
import 'product_search_screen.dart';
import 'customer_main_screen.dart';
import '../../models/address_model.dart';
import 'dart:async';

/// Modern Home Screen - Matches reference design
class HomeScreenNew extends StatefulWidget {
  const HomeScreenNew({super.key});

  @override
  State<HomeScreenNew> createState() => _HomeScreenNewState();
}

class _HomeScreenNewState extends State<HomeScreenNew> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<Product> _products = [];
  List<String> _categories = [];
  String _selectedCategory = 'All';
  bool _isLoading = true;
  Timer? _cacheTimer;
  Address? _selectedAddress;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadCategories();

    // Cache products periodically (every 5 minutes)
    _cacheTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _loadProducts(silent: true);
    });
  }

  @override
  void dispose() {
    _cacheTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadProducts({bool silent = false}) async {
    if (!silent) {
      setState(() => _isLoading = true);
    }

    try {
      final response = await apiService.get(
        '${ApiConfig.featuredProducts}?page=1&limit=20',
      );

      if (response.statusCode == 200) {
        final dynamic responseData = response.data;
        List<dynamic> data;

        if (responseData is Map<String, dynamic>) {
          data = responseData['products'] ?? responseData['data'] ?? [];
        } else if (responseData is List) {
          data = responseData;
        } else {
          data = [];
        }

        if (mounted) {
          setState(() {
            _products = data.map((json) => Product.fromJson(json)).toList();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('❌ Failed to load products: $e');
      if (mounted && !silent) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadCategories() async {
    try {
      final response = await apiService.get(ApiConfig.categories);
      if (response.statusCode == 200 && mounted) {
        final List<dynamic> data = response.data is List
            ? response.data
            : response.data['data'] ?? [];

        setState(() {
          _categories = ['All', ...data.map((c) => c['name'].toString()).toList()];
        });
      }
    } catch (e) {
      print('❌ Failed to load categories: $e');
    }
  }

  List<Product> get _filteredProducts {
    if (_selectedCategory == 'All') return _products;
    return _products
        .where((p) => p.category?.toLowerCase() == _selectedCategory.toLowerCase())
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header - Premium gradient with logo and location
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Top row: Logo, Location, and Notification
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Logo
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/logo/logo.png',
                          width: 36,
                          height: 36,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.store,
                              size: 36,
                              color: AppColors.primary,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Location indicator - Simplified
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LocationPickerScreen(),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.location_on_rounded,
                                  color: AppColors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    _selectedAddress?.label ?? 'Add Location',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.white,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: AppColors.white,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Notification bell - Simplified
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              Icons.notifications_none_rounded,
                              color: AppColors.white,
                              size: 20,
                            ),
                            // Notification badge
                            Positioned(
                              right: -1,
                              top: -1,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.error,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Search bar - Enhanced
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ProductSearchScreen(),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.search_rounded,
                                    color: AppColors.primary,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    'Search for groceries...',
                                    style: TextStyle(
                                      color: AppColors.grey500,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Filter button
                      GestureDetector(
                        onTap: _showFilterBottomSheet,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.primary,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.2),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.tune_rounded,
                            color: AppColors.primary,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadProducts,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // Horizontal Category Chips - Circular design
                      SizedBox(
                        height: 90,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _categories.length,
                          itemBuilder: (context, index) {
                            final category = _categories[index];
                            final isSelected = _selectedCategory == category;

                            return GestureDetector(
                              onTap: () {
                                setState(() => _selectedCategory = category);
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 16),
                                child: Column(
                                  children: [
                                    Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.primary // Logo blue when selected
                                            : AppColors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.08),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        _getCategoryIcon(category),
                                        color: isSelected
                                            ? AppColors.white
                                            : AppColors.grey600,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      category,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                        color: isSelected
                                            ? AppColors.textPrimary
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Special Offers Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Special Offers',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      '35% Discount',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      '100% Guaranteed all Fresh\nGrocery Items',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => const ProductsScreen(),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 10,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                      ),
                                      child: const Text(
                                        'Shop Now',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.all(12),
                                child: Image.asset(
                                  'assets/logo/logo.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.local_offer,
                                      size: 40,
                                      color: Colors.grey[400],
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Popular Items Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Popular Items',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ProductsScreen(),
                                  ),
                                );
                              },
                              child: const Text(
                                'View All',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Products Grid
                      _isLoading
                          ? Padding(
                              padding: const EdgeInsets.all(16),
                              child: GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.75,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                ),
                                itemCount: 6,
                                itemBuilder: (context, index) =>
                                    const ProductCardShimmer(),
                              ),
                            )
                          : _filteredProducts.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.shopping_bag_outlined,
                                        size: 80,
                                        color: AppColors.grey400,
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'No products available',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Check back later for new products',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      childAspectRatio: 0.75,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                    ),
                                    itemCount: _filteredProducts.length,
                                    itemBuilder: (context, index) {
                                      return ProductCard(
                                        product: _filteredProducts[index],
                                      );
                                    },
                                  ),
                                ),

                      const SizedBox(height: 20),
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

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => Container(
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
                  'Filter by Category',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Select a category to filter products',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),

            // Category Chips
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _categories.map((category) {
                final isSelected = _selectedCategory == category;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = category;
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.grey100,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.grey300,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getCategoryIcon(category),
                          color: isSelected ? AppColors.white : AppColors.textSecondary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          category,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? AppColors.white : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Reset Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _selectedCategory = 'All';
                  });
                  Navigator.pop(context);
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: const BorderSide(
                    color: AppColors.grey300,
                    width: 1.5,
                  ),
                ),
                child: const Text(
                  'Reset Filter',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'all':
        return Icons.apps;
      case 'veggie':
      case 'vegetables':
        return Icons.local_florist;
      case 'meat':
        return Icons.set_meal;
      case 'fruits':
        return Icons.apple;
      case 'fish':
      case 'seafood':
        return Icons.water;
      case 'dairy':
        return Icons.water_drop;
      case 'bakery':
        return Icons.bakery_dining;
      default:
        return Icons.category;
    }
  }
}
