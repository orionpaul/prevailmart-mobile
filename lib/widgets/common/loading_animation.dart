import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../config/app_colors.dart';

/// Advanced Loading Animations - Beautiful, modern loading states
class LoadingAnimation extends StatelessWidget {
  final LoadingType type;
  final String? message;
  final double size;

  const LoadingAnimation({
    super.key,
    this.type = LoadingType.cart,
    this.message,
    this.size = 120,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildAnimation(),
          if (message != null) ...[
            const SizedBox(height: 24),
            Text(
              message!,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnimation() {
    switch (type) {
      case LoadingType.cart:
        return _ShoppingCartAnimation(size: size);
      case LoadingType.delivery:
        return _DeliveryAnimation(size: size);
      case LoadingType.order:
        return _OrderAnimation(size: size);
      case LoadingType.search:
        return _SearchAnimation(size: size);
      case LoadingType.payment:
        return _PaymentAnimation(size: size);
      default:
        return _DefaultAnimation(size: size);
    }
  }
}

enum LoadingType {
  cart,
  delivery,
  order,
  search,
  payment,
  general,
}

/// Shopping Cart Loading Animation
class _ShoppingCartAnimation extends StatefulWidget {
  final double size;

  const _ShoppingCartAnimation({required this.size});

  @override
  State<_ShoppingCartAnimation> createState() => _ShoppingCartAnimationState();
}

class _ShoppingCartAnimationState extends State<_ShoppingCartAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _bounceAnimation = Tween<double>(begin: 0, end: 20).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
      ),
    );

    _rotationAnimation = Tween<double>(begin: -0.1, end: 0.1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -_bounceAnimation.value),
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: Offset(0, _bounceAnimation.value / 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.shopping_cart_rounded,
                color: Colors.white,
                size: 50,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Delivery Truck Animation
class _DeliveryAnimation extends StatefulWidget {
  final double size;

  const _DeliveryAnimation({required this.size});

  @override
  State<_DeliveryAnimation> createState() => _DeliveryAnimationState();
}

class _DeliveryAnimationState extends State<_DeliveryAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _wheelRotation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1.5, 0),
      end: const Offset(1.5, 0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _wheelRotation = Tween<double>(begin: 0, end: 8 * 3.14159).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size * 1.5,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Road/Track
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    AppColors.grey300,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Truck
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(_slideAnimation.value.dx * widget.size, 0),
                child: Container(
                  width: widget.size,
                  height: widget.size * 0.7,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.local_shipping_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Order Processing Animation
class _OrderAnimation extends StatefulWidget {
  final double size;

  const _OrderAnimation({required this.size});

  @override
  State<_OrderAnimation> createState() => _OrderAnimationState();
}

class _OrderAnimationState extends State<_OrderAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ring
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.rotate(
                angle: _controller.value * 2 * 3.14159,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                      width: 3,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 0,
                        left: widget.size / 2 - 6,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          // Inner circle with icon
          Container(
            width: widget.size * 0.6,
            height: widget.size * 0.6,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 20,
                ),
              ],
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
        ],
      ),
    );
  }
}

/// Search Animation
class _SearchAnimation extends StatefulWidget {
  final double size;

  const _SearchAnimation({required this.size});

  @override
  State<_SearchAnimation> createState() => _SearchAnimationState();
}

class _SearchAnimationState extends State<_SearchAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3 * _scaleAnimation.value),
                  blurRadius: 20 * _scaleAnimation.value,
                ),
              ],
            ),
            child: const Icon(
              Icons.search_rounded,
              color: Colors.white,
              size: 50,
            ),
          ),
        );
      },
    );
  }
}

/// Payment Processing Animation
class _PaymentAnimation extends StatefulWidget {
  final double size;

  const _PaymentAnimation({required this.size});

  @override
  State<_PaymentAnimation> createState() => _PaymentAnimationState();
}

class _PaymentAnimationState extends State<_PaymentAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulsing circles
          ...List.generate(3, (index) {
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final delay = index * 0.3;
                final value = (_controller.value - delay).clamp(0.0, 1.0);
                return Opacity(
                  opacity: 1.0 - value,
                  child: Transform.scale(
                    scale: 0.5 + (value * 0.7),
                    child: Container(
                      width: widget.size,
                      height: widget.size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary,
                          width: 3,
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }),
          // Center icon
          Container(
            width: widget.size * 0.5,
            height: widget.size * 0.5,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.payment_rounded,
              color: Colors.white,
              size: 35,
            ),
          ),
        ],
      ),
    );
  }
}

/// Default/General Loading Animation
class _DefaultAnimation extends StatefulWidget {
  final double size;

  const _DefaultAnimation({required this.size});

  @override
  State<_DefaultAnimation> createState() => _DefaultAnimationState();
}

class _DefaultAnimationState extends State<_DefaultAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _SpinnerPainter(
              progress: _controller.value,
              color: AppColors.primary,
            ),
          );
        },
      ),
    );
  }
}

class _SpinnerPainter extends CustomPainter {
  final double progress;
  final Color color;

  _SpinnerPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw multiple arcs
    for (int i = 0; i < 3; i++) {
      final startAngle = (progress * 2 * 3.14159) + (i * 2 * 3.14159 / 3);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - (i * 8)),
        startAngle,
        3.14159,
        false,
        paint..color = color.withOpacity(1.0 - (i * 0.3)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
