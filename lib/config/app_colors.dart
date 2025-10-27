import 'package:flutter/material.dart';

/// PrevailMart Premium Brand Colors - Clean & Professional
class AppColors {
  // Primary Brand Colors - PrevailMart Blue (exact match with website)
  static const Color primary = Color(0xFF4A5AAD); // PrevailMart Blue
  static const Color primaryDark = Color(0xFF3D4E99); // Darker Blue
  static const Color primaryLight = Color(0xFF5A6ABD);
  static const Color primaryLighter = Color(0xFF8A9ACD);

  // Secondary Colors - Clean Blue Accent
  static const Color secondary = Color(0xFF4A5AAD); // Use primary blue
  static const Color secondaryDark = Color(0xFF3D4E99);
  static const Color secondaryLight = Color(0xFF5A6ABD);

  // Accent Colors - Professional Palette
  static const Color accent = Color(0xFFFF6B6B); // Red from website
  static const Color accentGold = Color(0xFFFFD700); // Gold from website
  static const Color accentPink = Color(0xFFEC4899); // Pink
  static const Color accentPurple = Color(0xFF8B5CF6); // Purple
  static const Color warning = Color(0xFFFFA726); // Softer warning
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF22C55E); // Fresh Green
  static const Color info = Color(0xFF4A5AAD);

  // Gradients for Premium Look - Clean Blue Theme
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF4A5AAD), Color(0xFF3D4E99)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFFFA726), Color(0xFFFF9800)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF9FAFB)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);

  // Background Colors - Clean & Minimal
  static const Color background = Color(0xFFFAFAFA);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFF9FAFB);

  // Text Colors - Crisp & Clear
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnDark = Color(0xFFFFFFFF);

  // Border & Divider - Subtle
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderLight = Color(0xFFF3F4F6);
  static const Color divider = Color(0xFFEEEEEE);

  // Overlays - Smooth
  static Color overlay = Colors.black.withOpacity(0.5);
  static Color overlayLight = Colors.black.withOpacity(0.2);
  static Color overlayDark = Colors.black.withOpacity(0.7);

  // Shimmer Colors for Loading
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);

  // Shadow Colors
  static Color shadow = Colors.black.withOpacity(0.08);
  static Color shadowLight = Colors.black.withOpacity(0.04);
  static Color shadowMedium = Colors.black.withOpacity(0.12);
}
