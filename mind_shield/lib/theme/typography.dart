import 'package:flutter/material.dart';

import 'colors.dart';

/// App type scale. System sans-serif keeps the app readable without font downloads.
class AppTypography {
  static TextStyle get headlineLg => const TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.2,
  ).copyWith(color: AppColors.textPrimary);

  static TextStyle get headlineSm => const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.25,
  ).copyWith(color: AppColors.textPrimary);

  static TextStyle get bodyLg => const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  ).copyWith(color: AppColors.textPrimary);

  static TextStyle get bodyMd => const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  ).copyWith(color: AppColors.textPrimary);

  static TextStyle get bodySm => const TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.45,
  ).copyWith(color: AppColors.textSecondary);

  static TextStyle get _baseLabel => const TextStyle(
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  ).copyWith(color: AppColors.textPrimary);

  static TextStyle get labelLg => _baseLabel.copyWith(fontSize: 14);
  static TextStyle get labelMd => _baseLabel.copyWith(fontSize: 12);
  static TextStyle get labelSm => _baseLabel.copyWith(fontSize: 11);
}
