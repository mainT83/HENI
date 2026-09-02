import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../../models/oiseau.dart';
import '../../providers/oiseaux_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/locale_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/feather_icon.dart';

class OiseauxListScreen extends ConsumerWidget {
  const OiseauxListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).valueOrNull;
    final filter = ref.watch(oiseauxFilterProvider);
    final oiseauxAsync = ref.watch(oiseauxListProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t?.t('birds') ?? 'Oiseaux')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: t?.t('search') ?? 'Rechercher',
              ),
              onChanged: (v) => ref.read(oiseauxFilterProvider.notifier).state =
                  filter.copyWith(recherche: v),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _FilterChip(
                  label: 'Tous',
                  selected: filter.statut == null,
                  onTap: () => ref.read(oiseauxFilterProvider.notifier).state =
                      filter.copyWith(clearStatut: true),
                ),
                for (final statut in StatutOiseau.all)
                  _FilterChip(
                    label: _statutLabel(t, statut),
                    color: AppTheme.statutColor(statut),
                    selected: filter.statut == statut,
                    onTap: () => ref.read(oiseauxFilterProvider.notifier).state =
                        filter.copyWith(statut: statut),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: oiseauxAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('${t?.t('error_generic') ?? 'Erreur'}: $e')),
              data: (oiseaux) {
                if (oiseaux.isEmpty) {
                  return Center(child: Text(t?.t('no_results') ?? 'Aucun résultat'));
                }
                return RefreshIndicator(
                  onRefresh: () => ref.read(oiseauxListProvider.notifier).refresh(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: oiseaux.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) => _OiseauTile(oiseau: oiseaux[i], refEcran: ref),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/oiseaux/nouveau'),
        icon: const Icon(Icons.add),
        label: Text(t?.t('add_bird') ?? 'Ajouter un oiseau'),
      ),
    );
  }

  String _statutLabel(dynamic t, String statut) {
    switch (statut) {
      case StatutOiseau.reproducteur:
        return t?.t('status_breeder') ?? 'Reproducteur';
      case StatutOiseau.jeune:
        return t?.t('status_young') ?? 'Jeune';
      case StatutOiseau.aVendre:
        return t?.t('status_for_sale') ?? 'À vendre';
      case StatutOiseau.vendu:
        return t?.t('status_sold') ?? 'Vendu';
      case StatutOiseau.decede:
        return t?.t('status_deceased') ?? 'Décédé';
      default:
        return statut;
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.primary;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: c.withOpacity(0.15),
        labelStyle: TextStyle(color: selected ? c : Colors.black87),
        side: BorderSide(color: selected ? c : Colors.grey.shade300),
      ),
    );
  }
}

class _OiseauTile extends ConsumerWidget {
  final Oiseau oiseau;
  // ref de l'écran (OiseauxListScreen), stable tant qu'on reste sur la page —
  // contrairement au `ref` de cette tuile, détruit avec elle dès que la
  // suppression fait disparaître sa ligne de la liste en plein milieu de
  // l'opération.
  final WidgetRef refEcran;
  const _OiseauTile({required this.oiseau, required this.refEcran});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final especesAsync = ref.watch(especesProvider);
    final especeNom = especesAsync.maybeWhen(
      data: (especes) {
        final match = especes.where((e) => e.id == oiseau.especeId);
        return match.isEmpty ? '' : match.first.nomFr;
      },
      orElse: () => '',
    );

    final t = ref.watch(translationsProvider).valueOrNull;

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(10),
        leading: CircleAvatar(
          radius: 26,
          backgroundColor: Colors.grey.shade200,
          backgroundImage:
              oiseau.photoUrl != null ? CachedNetworkImageProvider(oiseau.photoUrl!) : null,
          child: oiseau.photoUrl == null
              ? const FeatherIcon(size: 20, color: Colors.grey)
              : null,
        ),
        title: Text(oiseau.nomAffiche, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${oiseau.bagueAvecAnnee} · $especeNom'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.statutColor(oiseau.statut).withOpacity(0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                oiseau.statut,
                style: TextStyle(color: AppTheme.statutColor(oiseau.statut), fontSize: 11),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppTheme.danger),
              tooltip: t?.t('delete') ?? 'Supprimer',
              onPressed: () => _supprimer(context, refEcran, oiseau, t),
            ),
          ],
        ),
        onTap: () => context.push('/oiseaux/${oiseau.id}'),
      ),
    );
  }

  Future<void> _supprimer(BuildContext context, WidgetRef ref, Oiseau oiseau, dynamic t) async {
    final confirme = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(t?.t('delete') ?? 'Supprimer'),
            content: Text(t?.t('delete_bird_confirm') ??
                'Confirmer la suppression de cet oiseau ?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(t?.t('cancel') ?? 'Annuler'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(t?.t('delete') ?? 'Supprimer',
                    style: const TextStyle(color: AppTheme.danger)),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirme || !context.mounted) return;

    // Capturés avant le await : la ligne de cet oiseau disparaît de la liste
    // dès que la suppression réussit, ce qui peut invalider `context` — sans
    // ça, le "if (context.mounted)" bloque la fermeture du dialogue de
    // chargement même après une suppression réussie.
    final navigator = Navigator.of(context, rootNavigator: true);
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      await ref.read(oiseauxListProvider.notifier).supprimer(oiseau.id);
      ref.invalidate(dashboardStatsProvider);
      navigator.pop();
    } catch (e) {
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(content: Text('${t?.t('error_generic') ?? 'Erreur'}: $e')),
      );
    }
  }
}
