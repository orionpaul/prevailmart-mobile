import 'package:flutter/material.dart';
import '../../config/app_colors.dart';

/// LIT Premium Custom Button - Lightweight, Modern, Sleek Design
class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final bool isWhite; // New: White button with primary border
  final Color? color;
  final Color? textColor;
  final IconData? icon;
  final double? width;
  final double height;
  final double borderRadius;
  final bool useGradient;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.isWhite = false, // New white variant
    this.color,
    this.textColor,
    this.icon,
    this.width,
    this.height = 52,
    this.borderRadius = 16, // More modern, less rounded
    this.useGradient = false,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      setState(() => _isPressed = true);
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final buttonColor = widget.color ?? AppColors.primary;
    final btnTextColor = widget.textColor ?? AppColors.white;

    // Determine button style
    Color? backgroundColor;
    Color textColor;
    Border? border;
    List<BoxShadow>? boxShadow;

    if (widget.isWhite) {
      // White button with primary border - LIT style
      backgroundColor = AppColors.white;
      textColor = buttonColor;
      border = Border.all(color: buttonColor, width: 2);
      boxShadow = !widget.isLoading
          ? [
              BoxShadow(
                color: buttonColor.withOpacity(_isPressed ? 0.15 : 0.2),
                blurRadius: _isPressed ? 8 : 12,
                offset: Offset(0, _isPressed ? 2 : 4),
              ),
            ]
          : null;
    } else if (widget.isOutlined) {
      backgroundColor = Colors.transparent;
      textColor = buttonColor;
      border = Border.all(color: buttonColor, width: 1.5);
      boxShadow = null;
    } else {
      backgroundColor = widget.useGradient ? null : buttonColor;
      textColor = btnTextColor;
      border = null;
      boxShadow = !widget.isLoading
          ? [
              BoxShadow(
                color: buttonColor.withOpacity(_isPressed ? 0.2 : 0.3),
                blurRadius: _isPressed ? 8 : 16,
                offset: Offset(0, _isPressed ? 2 : 4),
              ),
            ]
          : null;
    }

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: (details) {
          _handleTapUp(details);
          if (widget.onPressed != null && !widget.isLoading) {
            widget.onPressed!();
          }
        },
        onTapCancel: _handleTapCancel,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: widget.width ?? double.infinity,
          height: widget.height,
          decoration: BoxDecoration(
            gradient: (!widget.isOutlined && !widget.isWhite && widget.useGradient)
                ? AppColors.primaryGradient
                : null,
            color: backgroundColor,
            border: border,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: boxShadow,
          ),
          child: Center(
            child: _buildContent(textColor),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(Color contentColor) {
    if (widget.isLoading) {
      return SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(contentColor),
        ),
      );
    }

    if (widget.icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(widget.icon, size: 20, color: contentColor),
          const SizedBox(width: 8),
          Text(
            widget.text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: contentColor,
              letterSpacing: 0.3,
            ),
          ),
        ],
      );
    }

    return Text(
      widget.text,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: contentColor,
        letterSpacing: 0.3,
      ),
    );
  }
}
