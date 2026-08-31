import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/locale_provider.dart';
import '../../providers/theme_mode_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../core/theme/app_theme.dart';

class ReglagesScreen extends ConsumerWidget {
  const ReglagesScreen({super.key});

  Future<void> _afficherDefinirMotDePasse(BuildContext context) async {
    final succes = await showDialog<bool>(
      context: context,
      builder: (_) => const _DialogueDefinirMotDePasse(),
    );
    if (succes == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mot de passe défini.')),
      );
    }
  }

  void _afficherContactPremium(BuildContext context, dynamic t) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t?.t('free_limit_title') ?? 'Passer premium'),
        content: Text(t?.t('free_limit_message') ??
            'Contactez-nous pour passer en premium : oiseaux illimités et suivi généalogique inclus.'),
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
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(estPremium ? Icons.workspace_premium : Icons.workspace_premium_outlined,
                        color: estPremium ? AppTheme.amber : null),
                    title: Text(estPremium ? 'Plan Premium actif' : 'Plan gratuit'),
                    subtitle: Text(estPremium
                        ? 'Oiseaux illimités, suivi généalogique inclus'
                        : '10 oiseaux max, sans suivi généalogique'),
                  ),
                  if (!estPremium)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton(
                          onPressed: () => _afficherContactPremium(context, t),
                          child: const Text('Passer premium'),
                        ),
                      ),
                    ),
                ],
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
              leading: const Icon(Icons.lock_outline),
              title: const Text('Définir un mot de passe'),
              subtitle: const Text('Pour se connecter sans Google, depuis n\'importe quel appareil'),
              onTap: () => _afficherDefinirMotDePasse(context),
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

class _DialogueDefinirMotDePasse extends ConsumerStatefulWidget {
  const _DialogueDefinirMotDePasse();

  @override
  ConsumerState<_DialogueDefinirMotDePasse> createState() => _DialogueDefinirMotDePasseState();
}

class _DialogueDefinirMotDePasseState extends ConsumerState<_DialogueDefinirMotDePasse> {
  final _formKey = GlobalKey<FormState>();
  final _motDePasseCtrl = TextEditingController();
  final _confirmationCtrl = TextEditingController();
  bool _loading = false;
  String? _erreur;

  @override
  void dispose() {
    _motDePasseCtrl.dispose();
    _confirmationCtrl.dispose();
    super.dispose();
  }

  Future<void> _valider() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _erreur = null;
    });
    try {
      await ref.read(authRepositoryProvider).definirMotDePasse(_motDePasseCtrl.text);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _erreur = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Définir un mot de passe'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Utile pour te connecter sans Google, depuis n\'importe quel appareil.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _motDePasseCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Nouveau mot de passe'),
              validator: (v) => (v == null || v.length < 6) ? 'Minimum 6 caractères' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirmationCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirmer'),
              validator: (v) => v != _motDePasseCtrl.text ? 'Les mots de passe ne correspondent pas' : null,
            ),
            if (_erreur != null) ...[
              const SizedBox(height: 12),
              Text(_erreur!, style: const TextStyle(color: AppTheme.danger)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _loading ? null : _valider,
          child: _loading
              ? const SizedBox(
                  height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Enregistrer'),
        ),
      ],
    );
  }
}
