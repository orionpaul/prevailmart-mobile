import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import '../config/app_colors.dart';

/// Ultra Premium Splash Screen with Advanced Animations
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _glowController;
  late AnimationController _rotateController;
  late AnimationController _particleController;

  late Animation<double> _logoFadeAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimationSequence();
  }

  void _initializeAnimations() {
    // Logo entrance - dramatic scale and fade
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _logoScaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.elasticOut,
      ),
    );

    // Continuous glow pulse
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Elegant rotation
    _rotateController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _rotateAnimation = Tween<double>(begin: -0.1, end: 0.0).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.easeOutCubic),
    );

    // Animated particles
    _particleController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
  }

  void _startAnimationSequence() async {
    // Start logo animation
    await Future.delayed(const Duration(milliseconds: 100));
    _logoController.forward();
    _rotateController.forward();

    // Navigate to main app
    await Future.delayed(const Duration(milliseconds: 2500));
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _glowController.dispose();
    _rotateController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          // Light blur background with subtle gradient
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  AppColors.white,
                  AppColors.primary.withOpacity(0.02),
                  AppColors.white,
                ],
              ),
            ),
          ),

          // Subtle floating particles
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              return CustomPaint(
                size: Size(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height),
                painter: ParticlePainter(
                  animation: _particleController.value,
                  color: AppColors.primary.withOpacity(0.05),
                ),
              );
            },
          ),

          // Main content - Logo only
          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([_logoController, _glowController, _rotateController]),
              builder: (context, child) {
                return Opacity(
                  opacity: _logoFadeAnimation.value,
                  child: Transform.scale(
                    scale: _logoScaleAnimation.value,
                    child: Transform.rotate(
                      angle: _rotateAnimation.value,
                      child: Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.15 * _glowAnimation.value),
                              blurRadius: 40 * _glowAnimation.value,
                              spreadRadius: 10 * _glowAnimation.value,
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/logo/logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Particle Painter for subtle floating particles
class ParticlePainter extends CustomPainter {
  final double animation;
  final Color color;

  ParticlePainter({required this.animation, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Create 30 subtle particles
    for (int i = 0; i < 30; i++) {
      final random = math.Random(i);
      final x = size.width * random.nextDouble();
      final y = (size.height * random.nextDouble() + animation * size.height * 0.3) % size.height;
      final radius = 1.5 + random.nextDouble() * 2.5;

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;
}
