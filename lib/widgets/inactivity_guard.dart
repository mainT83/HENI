import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/auth_provider.dart';

/// Déconnecte automatiquement l'utilisateur après 5 minutes sans la moindre
/// interaction (clic/tap) — protection pour les appareils partagés, gratuite
/// et indépendante du plan Supabase (l'équivalent côté serveur, "Inactivity
/// timeout", est réservé au plan Pro).
///
/// Observe les évènements pointeur via `pointerRouter.addGlobalRoute` plutôt
/// qu'un `Listener` autour de toute l'app : un `Listener` englobant fait
/// partie de l'arbre de rendu et peut perturber l'arène de gestes de Flutter
/// (des clics ailleurs dans l'app — ex. confirmer une suppression — pouvaient
/// alors être rejetés en interne par erreur). Une route globale sur le
/// pointeur observe les évènements sans y participer.
class InactivityGuard extends ConsumerStatefulWidget {
  final Widget child;
  const InactivityGuard({super.key, required this.child});

  static const delaiInactivite = Duration(minutes: 5);

  @override
  ConsumerState<InactivityGuard> createState() => _InactivityGuardState();
}

class _InactivityGuardState extends ConsumerState<InactivityGuard> {
  Timer? _timer;

  void _reinitialiser() {
    _timer?.cancel();
    if (Supabase.instance.client.auth.currentSession == null) return;
    _timer = Timer(InactivityGuard.delaiInactivite, () {
      ref.read(authRepositoryProvider).signOut();
    });
  }

  void _surEvenementPointeur(PointerEvent event) {
    if (event is PointerDownEvent) _reinitialiser();
  }

  @override
  void initState() {
    super.initState();
    _reinitialiser();
    GestureBinding.instance.pointerRouter.addGlobalRoute(_surEvenementPointeur);
  }

  @override
  void dispose() {
    _timer?.cancel();
    GestureBinding.instance.pointerRouter.removeGlobalRoute(_surEvenementPointeur);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Redémarre aussi le minuteur à chaque connexion/déconnexion (pas
    // seulement au premier affichage du widget).
    ref.listen(authStateProvider, (_, __) => _reinitialiser());
    return widget.child;
  }
}
