import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import '../../models/product_model.dart';
import '../../widgets/customer/product_card.dart';
import '../../utils/logger.dart';
import 'customer_main_screen.dart';

/// Favorites/Wishlist Screen
/// Displays all products saved to the user's favorites
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final ApiService _apiService = ApiService();
  List<Product> _products = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFavoriteProducts();
  }

  Future<void> _loadFavoriteProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final favoritesProvider = context.read<FavoritesProvider>();
      final favoriteIds = favoritesProvider.favoriteIds;

      if (favoriteIds.isEmpty) {
        setState(() {
          _products = [];
          _isLoading = false;
        });
        return;
      }

      AppLogger.info('Loading ${favoriteIds.length} favorite products');

      // Fetch products by IDs
      final List<Product> products = [];
      for (final productId in favoriteIds) {
        try {
          final response = await _apiService.get('${ApiConfig.products}/$productId');
          if (response.data != null) {
            products.add(Product.fromJson(response.data));
          }
        } catch (e) {
          AppLogger.warning('Failed to load product: $productId', e);
        }
      }

      setState(() {
        _products = products;
        _isLoading = false;
      });

      AppLogger.success('Loaded ${products.length} favorite products');
    } catch (e) {
      AppLogger.error('Error loading favorite products', e);
      setState(() {
        _products = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final favoritesProvider = context.watch<FavoritesProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: const Text(
          'My Favorites',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (favoritesProvider.count > 0)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: () => _showClearConfirmation(context),
              tooltip: 'Clear all favorites',
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadFavoriteProducts,
        color: AppColors.primary,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final authProvider = context.watch<AuthProvider>();

    // Show login prompt if not authenticated
    if (!authProvider.isAuthenticated) {
      return _buildLoginPrompt();
    }

    // Show loading
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      );
    }

    // Show empty state
    if (_products.isEmpty) {
      return _buildEmptyState();
    }

    // Show products grid
    return _buildProductsGrid();
  }

  Widget _buildLoginPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_border,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Login to Save Favorites',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Sign in to save your favorite products and access them across all your devices',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Login Now',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
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
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.grey100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_border,
                size: 64,
                color: AppColors.grey400,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Favorites Yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Start adding products to your favorites by tapping the heart icon',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            OutlinedButton(
              onPressed: () {
                // Navigate to home tab to browse products
                CustomerMainScreen.switchTab(context, 0);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary, width: 2),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Browse Products',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsGrid() {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverToBoxAdapter(
            child: Text(
              '${_products.length} ${_products.length == 1 ? 'Product' : 'Products'}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return ProductCard(
                  product: _products[index],
                  onRemoved: () {
                    // Reload when product is removed from favorites
                    _loadFavoriteProducts();
                  },
                );
              },
              childCount: _products.length,
            ),
          ),
        ),
        const SliverPadding(
          padding: EdgeInsets.only(bottom: 20),
        ),
      ],
    );
  }

  Future<void> _showClearConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Favorites?'),
        content: const Text(
          'This will remove all products from your favorites list. This action cannot be undone.',
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text(
              'Clear All',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<FavoritesProvider>().clearFavorites();
      await _loadFavoriteProducts();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All favorites cleared'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }
}
