import 'package:flutter/material.dart';

/// Central semantic palette for the Mind Shield light-gradient visual system.
class AppColors {
  // Brand and actions
  static const Color primary = Color(0xFF3B82F6); // Accessible teal
  static const Color primaryPressed = Color(0xFF206A66);
  static const Color secondary = Color(0xFF596BC2); // Soft indigo
  static const Color command = Color(0xFF334155); // Deep navy for emphasis
  static const Color onAccent = Colors.white;

  // App surfaces
  static const Color background = Color(0xFFF6F8FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceContainerHigh = Color(0xFFEEF3F7);
  static const Color borderDefault = Color(0xFFE1E8EF);
  static const Color borderEmphasis = Color(0xFFBDC9D4);
  static const Color borderActive = primary;

  // Text
  static const Color textPrimary = Color(0xFF182433);
  static const Color textSecondary = Color(0xFF5D6C7C);
  static const Color textDisabled = Color(0xFF84919E);

  // Status colors; pair every status color with a text label.
  static const Color nominal = Color(0xFF2E7D32);
  static const Color nominalTint = Color(0xFFE8F5E9);
  static const Color advisory = Color(0xFF865100);
  static const Color advisoryTint = Color(0xFFFFF4DD);
  static const Color elevated = Color(0xFFB7473D);
  static const Color elevatedTint = Color(0xFFFFEEEB);
  static const Color alert = Color(0xFFB0231C);
  static const Color alertTint = Color(0xFFFCEBEA);
}
