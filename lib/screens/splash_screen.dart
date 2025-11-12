import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import '../config/app_colors.dart';

/// Elegant minimalist splash screen
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimationSequence();
  }

  void _initializeAnimations() {
    // Fade and scale animation for logo
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutBack,
    ));

    // Gentle pulse animation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    // Subtle shimmer effect
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat();

    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));
  }

  void _startAnimationSequence() async {
    // Start fade in
    await Future.delayed(const Duration(milliseconds: 300));
    _fadeController.forward();

    // Navigate to main app
    await Future.delayed(const Duration(milliseconds: 2500));
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF8FAFC),
              AppColors.white,
              Color(0xFFF1F5F9),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Subtle animated gradient circles
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _shimmerController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: GradientCirclesPainter(_shimmerAnimation.value),
                  );
                },
              ),
            ),

            // Main content
            Center(
              child: AnimatedBuilder(
                animation: _fadeController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo with elegant animation - bigger and no circle
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              final pulse = 1.0 + (_pulseController.value * 0.05);
                              return Transform.scale(
                                scale: pulse,
                                child: Container(
                                  width: 200,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withOpacity(0.15),
                                        blurRadius: 40,
                                        spreadRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: Image.asset(
                                    'assets/logo/logo.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 32),

                          // App name with shimmer
                          ShaderMask(
                            shaderCallback: (bounds) {
                              return LinearGradient(
                                colors: const [
                                  AppColors.primary,
                                  AppColors.secondary,
                                  AppColors.primary,
                                ],
                              ).createShader(bounds);
                            },
                            child: const Text(
                              'PrevailMart',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: AppColors.white,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Tagline
                          Text(
                            'Shop & Deliver in One App',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary.withOpacity(0.8),
                              letterSpacing: 1.2,
                            ),
                          ),

                          const SizedBox(height: 60),

                          // Minimal loading indicator
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary.withOpacity(0.3),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Version at bottom
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _fadeController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: Center(
                      child: Text(
                        'Version 1.0.0',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary.withOpacity(0.4),
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom painter for subtle background circles
class GradientCirclesPainter extends CustomPainter {
  final double animationValue;

  GradientCirclesPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Top-right circle
    paint.color = AppColors.primary.withOpacity(0.03);
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.2),
      100 + (animationValue * 20),
      paint,
    );

    // Bottom-left circle
    paint.color = AppColors.secondary.withOpacity(0.04);
    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.8),
      120 + (animationValue * 15),
      paint,
    );

    // Center circle
    paint.color = AppColors.primary.withOpacity(0.02);
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.5),
      150 + (animationValue * 10),
      paint,
    );
  }

  @override
  bool shouldRepaint(GradientCirclesPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
