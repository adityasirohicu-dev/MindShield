import 'package:flutter/material.dart';

/// Shared layout tokens. Use these instead of one-off spacing and corner values.
class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// Shared corner radii for controls and surfaces.
class AppRadii {
  static const BorderRadius small = BorderRadius.all(Radius.circular(8));
  static const BorderRadius control = BorderRadius.all(Radius.circular(12));
  static const BorderRadius card = BorderRadius.all(Radius.circular(18));
  static const BorderRadius panel = BorderRadius.all(Radius.circular(24));
  static const BorderRadius pill = BorderRadius.all(Radius.circular(999));
}

/// Light gradients used sparingly for welcoming, high-level surfaces.
class AppGradients {
  static const LinearGradient page = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF0FAF8), Color(0xFFF4F5FF), Color(0xFFF8FAFC)],
  );

  static const LinearGradient brand = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE2F6F1), Color(0xFFE8ECFF)],
  );

  static const LinearGradient warm = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFF4DF), Color(0xFFFFEAE6)],
  );
}

class AppElevation {
  static const double card = 1;
  static const double overlay = 4;
}

class AppTouchTarget {
  static const double minimum = 48;
}
