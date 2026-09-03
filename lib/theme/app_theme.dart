import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Aydınlık tema
  static const lightBackground = Color(0xFFF7F9FB);
  static const lightSurfaceContainerLow = Color(0xFFF2F4F6);
  static const lightSurfaceContainer = Color(0xFFECEEF0);
  static const lightSurfaceContainerHigh = Color(0xFFE6E8EA);
  static const lightSurfaceContainerHighest = Color(0xFFE0E3E5);
  static const lightSurfaceLowest = Color(0xFFFFFFFF);
  static const lightOnSurface = Color(0xFF191C1E);
  static const lightOnSurfaceVariant = Color(0xFF4A4455);
  static const lightOutlineVariant = Color(0xFFCCC3D8);

  // Karanlık tema — header dahil TÜM yüzeyler bu tonları kullanır.
  static const darkBgMain = Color(0xFF0B0F19);
  static const darkBgSecondary = Color(0xFF111827);
  static const darkCard = Color(0xFF1E293B);
  static const darkOnSurface = Color(0xFFF7F9FB);
  static const darkOnSurfaceVariant = Color(0xFFB6BCC7);

  // Marka / durum renkleri (her iki temada sabit)
  static const primary = Color(0xFF630ED4);
  static const primaryContainer = Color(0xFF7C3AED);
  static const neonPurple = Color(0xFFA855F7);
  static const onPrimary = Color(0xFFFFFFFF);

  static const secondary = Color(0xFF006C49);
  static const secondaryContainer = Color(0xFF6CF8BB);
  static const secondaryFixedDim = Color(0xFF4EDEA3);

  static const warning = Color(0xFFF5A524);
  static const error = Color(0xFFBA1A1A);
  static const errorContainer = Color(0xFFFFDAD6);
}

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: base.colorScheme.copyWith(
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        secondary: AppColors.secondary,
        secondaryContainer: AppColors.secondaryContainer,
        surface: AppColors.lightBackground,
        onSurface: AppColors.lightOnSurface,
        onSurfaceVariant: AppColors.lightOnSurfaceVariant,
        error: AppColors.error,
        errorContainer: AppColors.errorContainer,
        outlineVariant: AppColors.lightOutlineVariant,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.lightOnSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardColor: AppColors.lightSurfaceLowest,
      dividerColor: AppColors.lightSurfaceContainerHigh,
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.lightBackground.withValues(alpha: 0.92),
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        surfaceTintColor: Colors.transparent,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : Colors.white,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.lightSurfaceContainerHigh,
        ),
      ),
    );
  }

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.darkBgMain,
      colorScheme: base.colorScheme.copyWith(
        brightness: Brightness.dark,
        primary: AppColors.neonPurple,
        onPrimary: Colors.white,
        primaryContainer: AppColors.primaryContainer,
        secondary: AppColors.secondaryFixedDim,
        secondaryContainer: AppColors.secondary,
        surface: AppColors.darkBgMain,
        onSurface: AppColors.darkOnSurface,
        onSurfaceVariant: AppColors.darkOnSurfaceVariant,
        error: AppColors.error,
        errorContainer: AppColors.errorContainer,
        outlineVariant: const Color(0x33FFFFFF),
      ),
      // Karanlık modda header (AppBar) da diğer yüzeyler gibi koyu olur —
      // önceki tasarımdaki "her yerde koyu değil" sorunu burada düzeltildi.
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.darkOnSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardColor: AppColors.darkCard,
      dividerColor: const Color(0x1AFFFFFF),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.darkBgMain.withValues(alpha: 0.92),
        indicatorColor: AppColors.neonPurple.withValues(alpha: 0.18),
        surfaceTintColor: Colors.transparent,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => Colors.white,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.neonPurple
              : AppColors.darkCard,
        ),
      ),
    );
  }

  static Color statusColor(BuildContext context, {required bool isDark, required int daysRemaining, required bool expired}) {
    if (expired) return AppColors.error;
    if (daysRemaining <= 7) return AppColors.error;
    if (daysRemaining <= 30) return AppColors.warning;
    return isDark ? AppColors.secondaryFixedDim : AppColors.secondary;
  }
}
