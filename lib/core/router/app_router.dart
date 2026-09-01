import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/auth_provider.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/signup_screen.dart';
import '../../features/auth/definir_mot_de_passe_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/oiseaux/oiseaux_list_screen.dart';
import '../../features/oiseaux/oiseau_detail_screen.dart';
import '../../features/oiseaux/oiseau_form_screen.dart';
import '../../features/couples/couples_list_screen.dart';
import '../../features/couples/couple_form_screen.dart';
import '../../features/controller/controller_screen.dart';
import '../../features/pontes/pontes_list_screen.dart';
import '../../features/pontes/ponte_form_screen.dart';
import '../../features/pontes/ponte_detail_screen.dart';
import '../../features/traitements/traitements_list_screen.dart';
import '../../features/traitements/traitement_form_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/reglages/reglages_screen.dart';
import '../../widgets/app_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  ref.listen(authStateProvider, (previous, next) {
    if (next.valueOrNull?.event == AuthChangeEvent.passwordRecovery) {
      ref.read(recuperationMotDePasseProvider.notifier).state = true;
    }
  });

  return GoRouter(
    initialLocation: '/dashboard',
    refreshListenable: _AuthChangeNotifier(ref),
    redirect: (context, state) {
      final loggedIn = Supabase.instance.client.auth.currentSession != null;
      final onAuthPage = state.matchedLocation == '/login' || state.matchedLocation == '/signup';
      const motDePasseObligatoire = '/definir-mot-de-passe';

      if (!loggedIn && !onAuthPage) return '/login';
      if (loggedIn && onAuthPage) return '/dashboard';

      if (loggedIn && state.matchedLocation != motDePasseObligatoire) {
        final utilisateur = Supabase.instance.client.auth.currentUser;
        final identites = utilisateur?.identities ?? [];
        final connecteViaGoogle = identites.any((i) => i.provider == 'google');
        final aUnMotDePasse = utilisateur?.userMetadata?['password_defini'] == true;
        final enRecuperation = ref.read(recuperationMotDePasseProvider);
        if ((connecteViaGoogle && !aUnMotDePasse) || enRecuperation) return motDePasseObligatoire;
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (context, state) => const SignupScreen()),
      GoRoute(
        path: '/definir-mot-de-passe',
        builder: (context, state) => const DefinirMotDePasseScreen(),
      ),

      ShellRoute(
        builder: (context, state, child) =>
            AppShell(location: state.matchedLocation, child: child),
        routes: [
          GoRoute(path: '/dashboard', builder: (context, state) => const DashboardScreen()),
          GoRoute(
            path: '/oiseaux',
            builder: (context, state) => const OiseauxListScreen(),
            routes: [
              GoRoute(
                path: 'nouveau',
                builder: (context, state) => const OiseauFormScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) =>
                    OiseauDetailScreen(oiseauId: state.pathParameters['id']!),
              ),
              GoRoute(
                path: ':id/modifier',
                builder: (context, state) =>
                    OiseauFormScreen(oiseauId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: '/couples',
            builder: (context, state) => const CouplesListScreen(),
            routes: [
              GoRoute(
                path: 'nouveau',
                builder: (context, state) => const CoupleFormScreen(),
              ),
              GoRoute(
                path: ':id/modifier',
                builder: (context, state) =>
                    CoupleFormScreen(coupleId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: '/controleur',
            builder: (context, state) => const ControllerScreen(),
          ),
          GoRoute(
            path: '/pontes',
            builder: (context, state) => const PontesListScreen(),
            routes: [
              GoRoute(
                path: 'nouvelle',
                builder: (context, state) => const PonteFormScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) => PonteDetailScreen(ponteId: state.pathParameters['id']!),
              ),
              GoRoute(
                path: ':id/modifier',
                builder: (context, state) => PonteFormScreen(ponteId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: '/traitements',
            builder: (context, state) => const TraitementsListScreen(),
            routes: [
              GoRoute(
                path: 'nouveau',
                builder: (context, state) => TraitementFormScreen(
                  oiseauIdInitial: state.uri.queryParameters['oiseauId'],
                ),
              ),
              GoRoute(
                path: ':id/modifier',
                builder: (context, state) =>
                    TraitementFormScreen(traitementId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/reglages',
            builder: (context, state) => const ReglagesScreen(),
          ),
        ],
      ),
    ],
  );
});

/// Pont entre le Stream d'auth Riverpod et le `refreshListenable` attendu
/// par go_router (qui veut un Listenable, pas un Stream).
class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier(Ref ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
  }
}
