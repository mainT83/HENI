import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/locale_provider.dart';
import '../../providers/theme_mode_provider.dart';
import '../../providers/auth_provider.dart';

class ReglagesScreen extends ConsumerWidget {
  const ReglagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).valueOrNull;
    final localeCode = ref.watch(localeCodeProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t?.t('settings') ?? 'Réglages')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
