import 'package:flutter/material.dart';

import '../widgets/motion.dart';
import 'tokens.dart';
import 'typography.dart';

abstract final class AppTheme {
  static ThemeData light() {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.light);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.paper,
      colorScheme: const ColorScheme.light(
        primary: AppColors.sunflower,
        onPrimary: AppColors.ink,
        secondary: AppColors.tangerine,
        onSecondary: AppColors.ink,
        surface: AppColors.surface,
        onSurface: AppColors.ink,
        error: AppColors.tangerineDeep,
        onError: AppColors.surface,
        outline: AppColors.ink,
        outlineVariant: AppColors.lineSoft,
      ),
      // Umpan balik tekan memakai efek "ditekan ke kertas", bukan ripple
      splashFactory: NoSplash.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: AppPageTransitionsBuilder(),
          TargetPlatform.iOS: AppPageTransitionsBuilder(),
          TargetPlatform.macOS: AppPageTransitionsBuilder(),
          TargetPlatform.windows: AppPageTransitionsBuilder(),
          TargetPlatform.linux: AppPageTransitionsBuilder(),
          TargetPlatform.fuchsia: AppPageTransitionsBuilder(),
        },
      ),
      highlightColor: Colors.transparent,
      textTheme: base.textTheme.copyWith(
        displayLarge: AppText.displayXl,
        displayMedium: AppText.displayLg,
        titleLarge: AppText.titleLg,
        titleMedium: AppText.titleMd,
        bodyLarge: AppText.body,
        bodyMedium: AppText.body,
        bodySmall: AppText.bodySm,
        labelLarge: AppText.button,
        labelMedium: AppText.label,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: AppText.titleMd,
      ),
    );
  }
}
