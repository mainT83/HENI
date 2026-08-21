import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/i18n/app_translations.dart';

/// Code de langue courant ('fr' par défaut, changé au login selon le profil
/// éleveur ou manuellement dans les réglages).
final localeCodeProvider = StateProvider<String>((ref) => 'fr');

/// Charge les traductions correspondant à la langue courante.
final translationsProvider = FutureProvider<AppTranslations>((ref) async {
  final code = ref.watch(localeCodeProvider);
  return AppTranslations.load(code);
});
