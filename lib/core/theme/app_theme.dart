import 'package:flutter/material.dart';

/// Thème "SaaS premium" : sobre, moderne, une seule couleur d'accent.
class AppTheme {
  static const Color primary = Color(0xFF2F6FED);
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFD97706);
  static const Color danger = Color(0xFFDC2626);

  // Palette additionnelle façon AviBreed Pro, pour le tableau de bord.
  static const Color amber = Color(0xFFF59E0B);
  static const Color orange = Color(0xFFEA580C);
  static const Color purple = Color(0xFF9333EA);
  static const Color emerald = Color(0xFF10B981);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFF7F8FA),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(fontWeight: FontWeight.w700),
        titleLarge: TextStyle(fontWeight: FontWeight.w700),
        titleMedium: TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }

  /// Thème sombre inspiré d'AviBreed Pro (fond ardoise, cartes surélevées).
  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
    );

    const fondPage = Color(0xFF0B1220);
    const fondCarte = Color(0xFF0F172A);
    const bordure = Color(0xFF1E293B);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: fondPage,
      appBarTheme: const AppBarTheme(
        backgroundColor: fondPage,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: fondCarte,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: bordure),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fondCarte,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: bordure),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: fondCarte,
        indicatorColor: Color(0x332F6FED),
      ),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
        titleLarge: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
        titleMedium: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        bodyMedium: TextStyle(color: Color(0xFFCBD5E1)),
      ),
    );
  }

  /// Couleur associée à chaque statut d'oiseau (utilisée partout dans l'app)
  static Color statutColor(String statut) {
    switch (statut) {
      case 'reproducteur':
        return success;
      case 'jeune':
        return primary;
      case 'a_vendre':
        return warning;
      case 'vendu':
        return Colors.grey;
      case 'decede':
        return danger;
      default:
        return Colors.grey;
    }
  }

  /// Couleur associée au niveau de risque de consanguinité
  static Color risqueConsanguiniteColor(String niveau) {
    switch (niveau) {
      case 'tres_eleve':
        return danger;
      case 'eleve':
        return warning;
      case 'modere':
        return const Color(0xFFEAB308);
      default:
        return success;
    }
  }
}
