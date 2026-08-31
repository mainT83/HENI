import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../core/theme/app_theme.dart';

/// Affiché juste après une première connexion via Google : impose de
/// définir un mot de passe Nidus, pour pouvoir se reconnecter ensuite
/// sans dépendre de Google (autre appareil, session Google absente...).
class DefinirMotDePasseScreen extends ConsumerStatefulWidget {
  const DefinirMotDePasseScreen({super.key});

  @override
  ConsumerState<DefinirMotDePasseScreen> createState() => _DefinirMotDePasseScreenState();
}

class _DefinirMotDePasseScreenState extends ConsumerState<DefinirMotDePasseScreen> {
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
      // Le router réévalue normalement tout seul (identité "email" ajoutée),
      // mais on force la navigation aussi pour ne pas dépendre du timing.
      if (mounted) context.go('/dashboard');
    } catch (e) {
      setState(() => _erreur = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider).valueOrNull;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.lock_outline, size: 48, color: AppTheme.primary),
                    const SizedBox(height: 12),
                    Text(
                      'Définir un mot de passe',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ton compte est connecté via Google. Définis un mot de passe pour pouvoir aussi te connecter depuis un autre appareil, sans Google.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _motDePasseCtrl,
                      obscureText: true,
                      decoration: InputDecoration(labelText: t?.t('password') ?? 'Mot de passe'),
                      validator: (v) => (v == null || v.length < 6) ? 'Minimum 6 caractères' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _confirmationCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Confirmer le mot de passe'),
                      validator: (v) =>
                          v != _motDePasseCtrl.text ? 'Les mots de passe ne correspondent pas' : null,
                    ),
                    if (_erreur != null) ...[
                      const SizedBox(height: 12),
                      Text(_erreur!, style: const TextStyle(color: AppTheme.danger)),
                    ],
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _loading ? null : _valider,
                      child: _loading
                          ? const SizedBox(
                              height: 18, width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Enregistrer'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
