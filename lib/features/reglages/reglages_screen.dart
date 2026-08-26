import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/locale_provider.dart';
import '../../providers/theme_mode_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/payment_provider.dart';
import '../../core/theme/app_theme.dart';

class ReglagesScreen extends ConsumerStatefulWidget {
  const ReglagesScreen({super.key});

  @override
  ConsumerState<ReglagesScreen> createState() => _ReglagesScreenState();
}

class _ReglagesScreenState extends ConsumerState<ReglagesScreen> {
  bool _paiementEnCours = false;

  Future<void> _passerPremium({required bool viaPayPal}) async {
    setState(() => _paiementEnCours = true);
    try {
      final repo = ref.read(paymentRepositoryProvider);
      final payUrl =
          viaPayPal ? await repo.creerPaiementPremiumPayPal() : await repo.creerPaiementPremium();
      final ouvert = await launchUrl(Uri.parse(payUrl), mode: LaunchMode.externalApplication);
      if (!ouvert && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Impossible d'ouvrir la page de paiement")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    } finally {
      if (mounted) setState(() => _paiementEnCours = false);
    }
  }

  void _choisirMoyenPaiement() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.account_balance_wallet_outlined),
              title: const Text('Tunisie (carte, e-Dinar — Konnect)'),
              onTap: () {
                Navigator.of(context).pop();
                _passerPremium(viaPayPal: false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.public),
              title: const Text('International (PayPal)'),
              onTap: () {
                Navigator.of(context).pop();
                _passerPremium(viaPayPal: true);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider).valueOrNull;
    final localeCode = ref.watch(localeCodeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final premiumAsync = ref.watch(isPremiumProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t?.t('settings') ?? 'Réglages')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(isPremiumProvider),
        child: ListView(
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
                          onPressed: _paiementEnCours ? null : _choisirMoyenPaiement,
                          child: _paiementEnCours
                              ? const SizedBox(
                                  height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Passer premium'),
                        ),
                ),
              ),
            ),
            if (!(premiumAsync.valueOrNull ?? true))
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
                child: Text(
                  'Après paiement, revenez ici et tirez vers le bas pour actualiser votre statut.',
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
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
      ),
    );
  }
}
