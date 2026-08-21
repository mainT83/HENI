import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/locale_provider.dart';
import 'feather_icon.dart';

/// Coquille commune : barre de navigation basse (Tableau de bord / Oiseaux /
/// Couples). Les modules Pontes / Généalogie / etc. ajouteront leurs onglets
/// ici au fur et à mesure de leur développement.
class AppShell extends ConsumerWidget {
  final Widget child;
  final String location;
  const AppShell({super.key, required this.child, required this.location});

  int _indexForLocation(String location) {
    if (location.startsWith('/oiseaux')) return 1;
    if (location.startsWith('/couples')) return 2;
    if (location.startsWith('/controleur')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final translations = ref.watch(translationsProvider);
    final index = _indexForLocation(location);

    return Directionality(
      textDirection: translations.maybeWhen(
        data: (t) => t.isRtl ? TextDirection.rtl : TextDirection.ltr,
        orElse: () => TextDirection.ltr,
      ),
      child: Scaffold(
        body: SafeArea(child: child),
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (i) {
            switch (i) {
              case 0:
                context.go('/dashboard');
                break;
              case 1:
                context.go('/oiseaux');
                break;
              case 2:
                context.go('/couples');
                break;
              case 3:
                context.go('/controleur');
                break;
            }
          },
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.dashboard_outlined),
              selectedIcon: const Icon(Icons.dashboard),
              label: translations.maybeWhen(data: (t) => t.t('dashboard'), orElse: () => '...'),
            ),
            NavigationDestination(
              icon: const FeatherIcon(),
              selectedIcon: const FeatherIcon(filled: true),
              label: translations.maybeWhen(data: (t) => t.t('birds'), orElse: () => '...'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.favorite_outline),
              selectedIcon: const Icon(Icons.favorite),
              label: translations.maybeWhen(data: (t) => t.t('couples'), orElse: () => '...'),
            ),
            const NavigationDestination(
              icon: Icon(Icons.developer_board_outlined),
              selectedIcon: Icon(Icons.developer_board),
              label: 'Contrôleur',
            ),
          ],
        ),
      ),
    );
  }
}
