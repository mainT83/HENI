import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

/// Système de traduction simple basé sur des fichiers JSON (assets/translations/).
/// Volontairement sans passer par flutter_localizations/gen-l10n : pas d'étape
/// de génération de code à exécuter, juste des fichiers chargés au démarrage.
class AppTranslations {
  final String localeCode;
  final Map<String, String> _values;

  AppTranslations._(this.localeCode, this._values);

  static const supportedLocales = ['fr', 'ar', 'en'];
  static const rtlLocales = ['ar'];

  static Future<AppTranslations> load(String localeCode) async {
    final code = supportedLocales.contains(localeCode) ? localeCode : 'fr';
    final raw = await rootBundle.loadString('assets/translations/$code.json');
    final map = Map<String, dynamic>.from(json.decode(raw) as Map);
    return AppTranslations._(code, map.map((k, v) => MapEntry(k, v.toString())));
  }

  bool get isRtl => rtlLocales.contains(localeCode);

  String t(String key) => _values[key] ?? key;
}
