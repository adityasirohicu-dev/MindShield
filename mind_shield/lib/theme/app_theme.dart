import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'colors.dart';
import 'design_tokens.dart';
import 'typography.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.primary,
          onPrimary: AppColors.onAccent,
          secondary: AppColors.secondary,
          onSecondary: AppColors.onAccent,
          error: AppColors.alert,
          onError: AppColors.onAccent,
          surface: AppColors.surface,
          onSurface: AppColors.textPrimary,
          outline: AppColors.borderEmphasis,
        );

    return ThemeData(
      useMaterial3: true,
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
      }),
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,
      textTheme: TextTheme(
        displayLarge: AppTypography.headlineLg,
        displayMedium: AppTypography.headlineSm,
        bodyLarge: AppTypography.bodyLg,
        bodyMedium: AppTypography.bodyMd,
        bodySmall: AppTypography.bodySm,
        labelLarge: AppTypography.labelLg,
        labelMedium: AppTypography.labelMd,
        labelSmall: AppTypography.labelSm,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.headlineSm,
        shape: const Border(bottom: BorderSide(color: AppColors.borderDefault)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: const Color(0xFFDDF2EE),
        labelTextStyle: WidgetStatePropertyAll(AppTypography.labelSm),
        elevation: 0,
        height: 72,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: AppElevation.card,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.card,
          side: const BorderSide(color: AppColors.borderDefault),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadii.control,
          borderSide: const BorderSide(color: AppColors.borderEmphasis),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.control,
          borderSide: const BorderSide(color: AppColors.borderEmphasis),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.control,
          borderSide: const BorderSide(color: AppColors.secondary, width: 2),
        ),
        labelStyle: AppTypography.bodyMd.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, AppTouchTarget.minimum),
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.control),
          textStyle: AppTypography.labelMd,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, AppTouchTarget.minimum),
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.control),
          side: const BorderSide(color: AppColors.borderEmphasis),
          textStyle: AppTypography.labelMd,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.control),
      ),
    );
  }
}
