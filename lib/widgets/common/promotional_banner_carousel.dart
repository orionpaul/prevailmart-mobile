import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:async';
import '../../config/app_colors.dart';
import '../../models/promotional_banner_model.dart';
import '../../services/promotional_banner_service.dart';
import '../../utils/logger.dart';

/// Amazon-style Animated Promotional Banner Carousel
class PromotionalBannerCarousel extends StatefulWidget {
  final double height;
  final Duration autoPlayDuration;
  final Duration transitionDuration;
  final Curve transitionCurve;
  final bool autoPlay;
  final void Function(PromotionalBanner)? onBannerTap;

  const PromotionalBannerCarousel({
    super.key,
    this.height = 200,
    this.autoPlayDuration = const Duration(seconds: 5),
    this.transitionDuration = const Duration(milliseconds: 800),
    this.transitionCurve = Curves.easeInOut,
    this.autoPlay = true,
    this.onBannerTap,
  });

  @override
  State<PromotionalBannerCarousel> createState() => _PromotionalBannerCarouselState();
}

class _PromotionalBannerCarouselState extends State<PromotionalBannerCarousel>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  List<PromotionalBanner> _banners = [];
  bool _isLoading = true;
  int _currentPage = 0;
  Timer? _autoPlayTimer;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_fadeController);

    _loadBanners();
    _setupAutoPlay();
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadBanners() async {
    setState(() => _isLoading = true);

    final banners = await PromotionalBannerService.getActiveBanners();

    if (mounted) {
      setState(() {
        _banners = banners;
        _isLoading = false;
      });

      if (_banners.isNotEmpty) {
        _fadeController.forward();
        // Track view for first banner
        _trackBannerView(_banners[0].id);
      }
    }
  }

  void _setupAutoPlay() {
    if (widget.autoPlay) {
      _autoPlayTimer = Timer.periodic(widget.autoPlayDuration, (_) {
        if (_banners.isEmpty) return;

        final nextPage = (_currentPage + 1) % _banners.length;
        _pageController.animateToPage(
          nextPage,
          duration: widget.transitionDuration,
          curve: widget.transitionCurve,
        );
      });
    }
  }

  void _trackBannerView(String bannerId) {
    PromotionalBannerService.trackBannerView(bannerId);
  }

  void _trackBannerClick(String bannerId) {
    PromotionalBannerService.trackBannerClick(bannerId);
  }

  void _handleBannerTap(PromotionalBanner banner) {
    _trackBannerClick(banner.id);

    if (widget.onBannerTap != null) {
      widget.onBannerTap!(banner);
    } else if (banner.actionUrl != null) {
      AppLogger.banner('Navigating to: ${banner.actionUrl}');
      // TODO: Implement deep linking / navigation
    }
  }

  Color _getColorForTheme(String theme) {
    switch (theme) {
      case 'primary':
        return AppColors.primary;
      case 'secondary':
        return AppColors.secondary;
      case 'success':
        return AppColors.success;
      case 'warning':
        return const Color(0xFFFFA726);
      case 'info':
        return AppColors.info;
      case 'error':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingShimmer();
    }

    if (_banners.isEmpty) {
      return const SizedBox.shrink();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          // Banner Carousel
          SizedBox(
            height: widget.height,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
                _trackBannerView(_banners[index].id);
              },
              itemCount: _banners.length,
              itemBuilder: (context, index) {
                return _buildBannerItem(_banners[index]);
              },
            ),
          ),

          // Indicator Dots
          if (_banners.length > 1)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _banners.length,
                  (index) => _buildIndicatorDot(index),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBannerItem(PromotionalBanner banner) {
    final themeColor = _getColorForTheme(banner.colorTheme);

    return GestureDetector(
      onTap: () => _handleBannerTap(banner),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: themeColor.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 6),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Banner Image
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: banner.displayImage,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: AppColors.grey100,
                    highlightColor: AppColors.white,
                    child: Container(color: AppColors.grey100),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: themeColor.withOpacity(0.1),
                    child: Center(
                      child: Icon(
                        Icons.campaign_rounded,
                        size: 64,
                        color: themeColor,
                      ),
                    ),
                  ),
                ),
              ),

              // Gradient Overlay for better text visibility
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.black.withOpacity(0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Banner Content
              Positioned(
                left: 20,
                right: 20,
                bottom: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Text(
                      banner.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.2,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 6),

                    // Description
                    Text(
                      banner.description,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.95),
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    if (banner.actionText != null) ...[
                      const SizedBox(height: 12),

                      // Action Button
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              themeColor,
                              themeColor.withOpacity(0.85),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: themeColor.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              banner.actionText!,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Discount Badge (if applicable)
              if (banner.discountPercentage != null)
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.error,
                          AppColors.error.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.error.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '${banner.discountPercentage!.toInt()}% OFF',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIndicatorDot(int index) {
    final isActive = index == _currentPage;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        gradient: isActive
            ? LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withOpacity(0.7),
                ],
              )
            : null,
        color: isActive ? null : AppColors.grey300,
        borderRadius: BorderRadius.circular(4),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.4),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: AppColors.grey100,
      highlightColor: AppColors.white,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        height: widget.height,
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
