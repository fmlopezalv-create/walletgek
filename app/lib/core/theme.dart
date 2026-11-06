import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Cifras tabulares: los números mantienen el mismo ancho, ideales para montos.
const _tabular = [FontFeature.tabularFigures()];

TextTheme _textTheme(TextTheme base) {
  return base.copyWith(
    // Títulos — Plus Jakarta Sans (preservando el color del tema)
    headlineLarge: GoogleFonts.plusJakartaSans(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        fontFeatures: _tabular,
        color: base.headlineLarge?.color), // saldo principal
    headlineMedium: GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        fontFeatures: _tabular,
        color: base.headlineMedium?.color), // H1
    headlineSmall: GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        fontFeatures: _tabular,
        color: base.headlineSmall?.color), // H2
    titleLarge: GoogleFonts.plusJakartaSans(
        fontSize: 20, fontWeight: FontWeight.w600, color: base.titleLarge?.color),
    titleMedium: GoogleFonts.plusJakartaSans(
        fontSize: 16, fontWeight: FontWeight.w600, color: base.titleMedium?.color),
    titleSmall: GoogleFonts.plusJakartaSans(
        fontSize: 14, fontWeight: FontWeight.w600, color: base.titleSmall?.color),
    // Texto de interfaz — Inter (preservando el color del tema)
    bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        fontFeatures: _tabular,
        color: base.bodyLarge?.color),
    bodyMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        fontFeatures: _tabular,
        color: base.bodyMedium?.color),
    bodySmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        fontFeatures: _tabular,
        color: base.bodySmall?.color),
    labelLarge: GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w500, color: base.labelLarge?.color),
    labelMedium: GoogleFonts.inter(
        fontSize: 12, fontWeight: FontWeight.w500, color: base.labelMedium?.color),
    labelSmall: GoogleFonts.inter(
        fontSize: 12, fontWeight: FontWeight.w400, color: base.labelSmall?.color),
  );
}

ThemeData _base(ThemeData theme) {
  return theme.copyWith(
    textTheme: _textTheme(theme.textTheme),
    cardTheme: CardThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      margin: EdgeInsets.zero,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
  );
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.emerald,
    brightness: Brightness.light,
  ).copyWith(
    primary: AppColors.emeraldDeep,
    secondary: AppColors.champagneGold,
    error: AppColors.coral,
    surface: AppColors.iceWhite,
    onSurface: AppColors.midnightNavy,
  );
  final theme = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.iceWhite,
  );
  return _base(theme).copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.midnightNavy,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: AppColors.emerald.withValues(alpha: 0.15),
      height: 60,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStatePropertyAll(
        GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500),
      ),
      iconTheme: const WidgetStatePropertyAll(
        IconThemeData(size: 22),
      ),
    ),
  );
}

ThemeData buildDarkTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.emerald,
    brightness: Brightness.dark,
  ).copyWith(
    primary: AppColors.emerald,
    secondary: AppColors.champagneGold,
    error: AppColors.coral,
    surface: AppColors.navy700,
    onSurface: AppColors.iceWhite,
  );
  final theme = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.midnightBlack,
    cardColor: AppColors.navy700,
  );
  return _base(theme).copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.midnightBlack,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.navy700,
      indicatorColor: AppColors.emerald.withValues(alpha: 0.18),
      height: 60,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStatePropertyAll(
        GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500),
      ),
      iconTheme: WidgetStatePropertyAll(
        IconThemeData(size: 22),
      ),
    ),
  );
}
