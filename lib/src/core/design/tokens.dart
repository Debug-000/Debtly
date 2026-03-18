import 'package:flutter/material.dart';

import '../../domain/models/models.dart';

class AppRadius {
  static const double xs = 10;
  static const double sm = 14;
  static const double md = 18;
  static const double lg = 24;
  static const double xl = 32;
}

class AppSpace {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 40;
}

class AppPalette {
  static const Color background = Color(0xFF0B0B0B);
  static const Color backgroundSoft = Color(0xFF111111);
  static const Color surface = Color(0xFF1B1B1B);
  static const Color surfaceRaised = Color(0xFF222222);
  static const Color surfaceMuted = Color(0xFF2B2B2B);
  static const Color border = Color(0xFF323232);
  static const Color borderStrong = Color(0xFF3A3A3A);

  static const Color textPrimary = Color(0xFFF6F8FB);
  static const Color textSecondary = Color(0xFFBCC5D1);
  static const Color textMuted = Color(0xFF88919D);

  static const Color success = Color(0xFF7BB596);
  static const Color warning = Color(0xFFE0AA6B);
  static const Color danger = Color(0xFFD98074);
  static const Color info = Color(0xFF86A8C8);
}

class AppShadows {
  static const List<BoxShadow> soft = [
    BoxShadow(
      color: Color(0x26000000),
      blurRadius: 28,
      offset: Offset(0, 14),
    ),
  ];

  static const List<BoxShadow> subtle = [
    BoxShadow(
      color: Color(0x18000000),
      blurRadius: 16,
      offset: Offset(0, 8),
    ),
  ];
}

class AppAccentColors extends ThemeExtension<AppAccentColors> {
  const AppAccentColors({
    required this.primary,
    required this.soft,
    required this.deep,
  });

  final Color primary;
  final Color soft;
  final Color deep;

  @override
  AppAccentColors copyWith({
    Color? primary,
    Color? soft,
    Color? deep,
  }) {
    return AppAccentColors(
      primary: primary ?? this.primary,
      soft: soft ?? this.soft,
      deep: deep ?? this.deep,
    );
  }

  @override
  AppAccentColors lerp(ThemeExtension<AppAccentColors>? other, double t) {
    if (other is! AppAccentColors) return this;
    return AppAccentColors(
      primary: Color.lerp(primary, other.primary, t) ?? primary,
      soft: Color.lerp(soft, other.soft, t) ?? soft,
      deep: Color.lerp(deep, other.deep, t) ?? deep,
    );
  }

  static AppAccentColors fromTheme(AccentTheme theme) {
    return switch (theme) {
      AccentTheme.ocean => const AppAccentColors(
          primary: Color(0xFF6AA6FF),
          soft: Color(0xFF4977BB),
          deep: Color(0xFF314F7A),
        ),
      AccentTheme.violet => const AppAccentColors(
          primary: Color(0xFFA07BFF),
          soft: Color(0xFF7858C8),
          deep: Color(0xFF563C8E),
        ),
      AccentTheme.ruby => const AppAccentColors(
          primary: Color(0xFFF06B7A),
          soft: Color(0xFFBD5560),
          deep: Color(0xFF833D45),
        ),
      AccentTheme.emerald => const AppAccentColors(
          primary: Color(0xFF5FD0A2),
          soft: Color(0xFF44A57D),
          deep: Color(0xFF2F7157),
        ),
    };
  }
}

extension AppThemeContext on BuildContext {
  AppAccentColors get accentColors =>
      Theme.of(this).extension<AppAccentColors>() ??
      AppAccentColors.fromTheme(AccentTheme.ocean);
}
