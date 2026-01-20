import 'package:flutter/material.dart';

/// Centralized color definitions for the app.
/// Modify these values to change the app's color scheme.
class AppColors {
  AppColors._();

  // Primary colors - Pink
  static const Color primary = Color(0xFFE91E63);
  static const Color primaryDark = Color(0xFFC2185B);
  static const Color primaryLight = Color(0xFFF8BBD9);

  // Background & Surface - Black theme
  static const Color background = Color(0xFF000000);
  static const Color surface = Color(0xFF1A1A1A);
  static const Color surfaceLight = Color(0xFF2D2D2D);
  static const Color card = Color(0xFF1E1E1E);

  // Text colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB3B3B3);
  static const Color textHint = Color(0xFF757575);

  // Accent & Status colors
  static const Color accent = Color(0xFFFF4081);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFE53935);

  // Additional UI colors
  static const Color divider = Color(0xFF2D2D2D);
  static const Color border = Color(0xFF3D3D3D);
  static const Color iconDefault = Color(0xFFB3B3B3);
  static const Color badgeBackground = Color(0xFF4CAF50);
}
