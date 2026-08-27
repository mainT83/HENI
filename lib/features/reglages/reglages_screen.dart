import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/locale_provider.dart';
import '../../providers/theme_mode_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../core/theme/app_theme.dart';

class ReglagesScreen extends ConsumerWidget {
  const ReglagesScreen({super.key});

  void _afficherContactPremium(BuildContext context, dynamic t) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t?.t('free_limit_title') ?? 'Passer premium'),
        content: Text(t?.t('free_limit_message') ??
            'Contactez-nous pour passer en premium : oiseaux illimités et suivi généalogique débloqué.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(t?.t('cancel') ?? 'Fermer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).valueOrNull;
    final localeCode = ref.watch(localeCodeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final premiumAsync = ref.watch(isPremiumProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t?.t('settings') ?? 'Réglages')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          premiumAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (estPremium) => Card(
              child: ListTile(
                leading: Icon(estPremium ? Icons.workspace_premium : Icons.workspace_premium_outlined,
                    color: estPremium ? AppTheme.amber : null),
                title: Text(estPremium ? 'Plan Premium actif' : 'Plan gratuit'),
                subtitle: Text(estPremium
                    ? 'Oiseaux illimités, suivi généalogique débloqué'
                    : '10 oiseaux max, sans suivi généalogique'),
                trailing: estPremium
                    ? null
                    : FilledButton(
                        onPressed: () => _afficherContactPremium(context, t),
                        child: const Text('Passer premium'),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.language),
                  title: Text('Langue'),
                ),
                RadioListTile<String>(
                  title: const Text('Français'),
                  value: 'fr',
                  groupValue: localeCode,
                  onChanged: (v) => ref.read(localeCodeProvider.notifier).state = v!,
                ),
                RadioListTile<String>(
                  title: const Text('العربية'),
                  value: 'ar',
                  groupValue: localeCode,
                  onChanged: (v) => ref.read(localeCodeProvider.notifier).state = v!,
                ),
                RadioListTile<String>(
                  title: const Text('English'),
                  value: 'en',
                  groupValue: localeCode,
                  onChanged: (v) => ref.read(localeCodeProvider.notifier).state = v!,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: SwitchListTile(
              secondary: Icon(themeMode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode),
              title: const Text('Mode sombre'),
              value: themeMode == ThemeMode.dark,
              onChanged: (actif) => ref.read(themeModeProvider.notifier).state =
                  actif ? ThemeMode.dark : ThemeMode.light,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: Text(t?.t('logout') ?? 'Déconnexion', style: const TextStyle(color: Colors.red)),
              onTap: () => ref.read(authRepositoryProvider).signOut(),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text('Nidus — v0.1.0', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
