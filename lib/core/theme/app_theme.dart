import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Thème "Couvée" : chaleureux et arrondi, sauge + terre cuite — met en
/// avant le soin apporté aux oiseaux plutôt que la donnée brute.
class AppTheme {
  static const Color primary = Color(0xFF5B7553); // sauge
  static const Color success = Color(0xFF4F7A41); // vert feuille
  static const Color warning = Color(0xFFE2A640); // ambre/soleil
  static const Color danger = Color(0xFFB3453A); // terre cuite rouge

  // Palette additionnelle pour le tableau de bord (cartes clés).
  static const Color amber = Color(0xFFE2A640); // soleil
  static const Color orange = Color(0xFFC1683F); // argile
  static const Color purple = Color(0xFF8C6A9C); // prune
  static const Color emerald = Color(0xFF6B8F5E); // vert tendre

  static TextTheme _texteClair() {
    final base = GoogleFonts.figtreeTextTheme();
    return base.copyWith(
      headlineSmall: GoogleFonts.newsreader(
          fontStyle: FontStyle.italic, fontWeight: FontWeight.w500, fontSize: 24, color: const Color(0xFF2E3625)),
      titleLarge: GoogleFonts.newsreader(
          fontStyle: FontStyle.italic, fontWeight: FontWeight.w500, fontSize: 20, color: const Color(0xFF2E3625)),
      titleMedium: GoogleFonts.newsreader(
          fontStyle: FontStyle.italic, fontWeight: FontWeight.w500, fontSize: 17, color: const Color(0xFF2E3625)),
      bodyMedium: GoogleFonts.figtree(color: const Color(0xFF2E3625)),
      bodySmall: GoogleFonts.figtree(color: const Color(0xFF6B7259)),
    );
  }

  static TextTheme _texteSombre() {
    final base = GoogleFonts.figtreeTextTheme();
    return base.copyWith(
      headlineSmall: GoogleFonts.newsreader(
          fontStyle: FontStyle.italic, fontWeight: FontWeight.w500, fontSize: 24, color: const Color(0xFFECE7DA)),
      titleLarge: GoogleFonts.newsreader(
          fontStyle: FontStyle.italic, fontWeight: FontWeight.w500, fontSize: 20, color: const Color(0xFFECE7DA)),
      titleMedium: GoogleFonts.newsreader(
          fontStyle: FontStyle.italic, fontWeight: FontWeight.w500, fontSize: 17, color: const Color(0xFFECE7DA)),
      bodyMedium: GoogleFonts.figtree(color: const Color(0xFFECE7DA)),
      bodySmall: GoogleFonts.figtree(color: const Color(0xFFA8AC98)),
    );
  }

  static ThemeData light() {
    const ground = Color(0xFFF6F3EC); // fond crème chaud
    const surface = Color(0xFFFFFFFF);
    const ink = Color(0xFF2E3625);
    const line = Color(0xFFDDE3D0);

    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ).copyWith(surface: surface, error: danger);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: ground,
      textTheme: _texteClair(),
      appBarTheme: AppBarTheme(
        backgroundColor: ground,
        foregroundColor: ink,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.newsreader(
            fontStyle: FontStyle.italic, fontWeight: FontWeight.w500, fontSize: 20, color: ink),
      ),
      cardTheme: CardThemeData(
        elevation: 3,
        color: surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: primary.withOpacity(0.12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: line),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          side: const BorderSide(color: line),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: primary.withOpacity(0.14),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: primary.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        side: BorderSide.none,
      ),
    );
  }

  /// Thème sombre "Couvée" — même chaleur organique, fond brun profond
  /// plutôt qu'un gris/bleu ardoise générique.
  static ThemeData dark() {
    const fondPage = Color(0xFF211F19);
    const fondCarte = Color(0xFF2A2822);
    const bordure = Color(0xFF3A372E);
    const ink = Color(0xFFECE7DA);
    const primaireSombre = Color(0xFF8FAE82);

    final scheme = ColorScheme.fromSeed(
      seedColor: primaireSombre,
      brightness: Brightness.dark,
    ).copyWith(surface: fondCarte, error: const Color(0xFFD97B6E));

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: fondPage,
      textTheme: _texteSombre(),
      appBarTheme: AppBarTheme(
        backgroundColor: fondPage,
        foregroundColor: ink,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.newsreader(
            fontStyle: FontStyle.italic, fontWeight: FontWeight.w500, fontSize: 20, color: ink),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: fondCarte,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: bordure),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fondCarte,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: bordure),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaireSombre,
          foregroundColor: const Color(0xFF1A2116),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaireSombre,
          foregroundColor: const Color(0xFF1A2116),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          side: const BorderSide(color: bordure),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: fondCarte,
        indicatorColor: primaireSombre.withOpacity(0.2),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: primaireSombre.withOpacity(0.16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        side: BorderSide.none,
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
        return const Color(0xFFC9A227);
      default:
        return success;
    }
  }
}
