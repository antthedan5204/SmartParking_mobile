import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary
  static const Color primary = Color(0xFF3F51B5);
  static const Color primaryDark = Color(0xFF303F9F);
  static const Color primaryLight = Color(0xFFC5CAE9);
  static const Color accent = Color(0xFFFF4081);

  // Background
  static const Color background = Color(0xFFF5F5F7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFECEFF1);
  static const Color homeBackground = Color(0xFFF0F4FF);

  // Status
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color danger = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // Figma-specific status backgrounds
  static const Color lotAvailable = Color(0xFFE3F2FD);  // Light Blue backdrop
  static const Color lotFull = Color(0xFFFFEBEE);       // Light Pink backdrop

  // Text
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnDark = Color(0xFFFFFFFF);

  // Border
  static const Color border = Color(0xFFE0E0E0);
  static const Color borderLight = Color(0xFFF5F5F5);

  // Shadow & Divider
  static const Color shadow = Color(0x1A000000);
  static const Color divider = Color(0xFFE0E0E0);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF3F51B5), Color(0xFF303F9F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient homeHeaderGradient = LinearGradient(
    colors: [Color(0xFF3F51B5), Color(0xFF5C6BC0), Color(0xFF7986CB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient adminGradient = LinearGradient(
    colors: [Color(0xFF1A237E), Color(0xFF311B92)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Occupancy levels
  static const Color occupancyHigh = Color(0xFF4CAF50);    // > 50% free
  static const Color occupancyMedium = Color(0xFFFF9800);   // 20-50% free
  static const Color occupancyLow = Color(0xFFF44336);      // < 20% free

  // Quick Actions
  static const Color quickActionBookings = Color(0xFF00897B);
  static const Color quickActionHelp = Color(0xFFFB8C00);
}
