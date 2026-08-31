import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/oiseau.dart';
import '../../data/oiseaux_repository.dart';
import '../../providers/oiseaux_provider.dart';
import '../../providers/locale_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/feather_icon.dart';
import '../../providers/traitements_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/premium_locked_card.dart';
import '../traitements/traitements_list_screen.dart';

class OiseauDetailScreen extends ConsumerWidget {
  final String oiseauId;
  const OiseauDetailScreen({super.key, required this.oiseauId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).valueOrNull;
    final oiseauAsync = ref.watch(oiseauDetailProvider(oiseauId));

    return Scaffold(
      appBar: AppBar(
        title: Text(t?.t('birds') ?? 'Oiseau'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/oiseaux/$oiseauId/modifier'),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(t?.t('delete') ?? 'Supprimer'),
                  content: const Text('Confirmer la suppression de cet oiseau ?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(t?.t('cancel') ?? 'Annuler')),
                    TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(t?.t('delete') ?? 'Supprimer')),
                  ],
                ),
              );
              if (confirm == true) {
                await ref.read(oiseauxRepositoryProvider).delete(oiseauId);
                ref.invalidate(oiseauxListProvider);
                ref.invalidate(dashboardStatsProvider);
                ref.invalidate(tendanceMensuelleProvider);
                ref.invalidate(incubationsActivesProvider);
                if (context.mounted) context.pop();
              }
            },
          ),
        ],
      ),
      body: oiseauAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('${t?.t('error_generic') ?? 'Erreur'}: $e')),
        data: (oiseau) => _DetailBody(oiseau: oiseau),
      ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  final Oiseau oiseau;
  const _DetailBody({required this.oiseau});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).valueOrNull;
    final especes = ref.watch(especesProvider).valueOrNull ?? [];
    final especeNom = especes.where((e) => e.id == oiseau.especeId).isNotEmpty
        ? especes.firstWhere((e) => e.id == oiseau.especeId).nomFr
        : '';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: CircleAvatar(
            radius: 56,
            backgroundColor: Colors.grey.shade200,
            backgroundImage:
                oiseau.photoUrl != null ? CachedNetworkImageProvider(oiseau.photoUrl!) : null,
            child: oiseau.photoUrl == null
                ? const FeatherIcon(size: 36, color: Colors.grey)
                : null,
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(oiseau.nomAffiche, style: Theme.of(context).textTheme.titleLarge),
        ),
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.statutColor(oiseau.statut).withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(oiseau.statut, style: TextStyle(color: AppTheme.statutColor(oiseau.statut))),
          ),
        ),
        const SizedBox(height: 20),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _InfoRow(label: t?.t('ring_number') ?? 'Bague', value: oiseau.numeroBague),
                _InfoRow(label: t?.t('species') ?? 'Espèce', value: especeNom),
                _InfoRow(label: t?.t('breed') ?? 'Race', value: oiseau.race ?? '—'),
                _InfoRow(label: t?.t('mutation') ?? 'Mutation', value: oiseau.mutation ?? '—'),
                _InfoRow(label: t?.t('sex') ?? 'Sexe', value: _sexeLabel(t, oiseau.sexe)),
                _InfoRow(
                  label: t?.t('birth_date') ?? 'Naissance',
                  value: oiseau.dateNaissance != null
                      ? DateFormat('dd/MM/yyyy').format(oiseau.dateNaissance!)
                      : '—',
                ),
                _InfoRow(
                    label: t?.t('origin_breeder') ?? "Éleveur d'origine",
                    value: oiseau.eleveurOrigine ?? '—'),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        if (oiseau.pereId != null || oiseau.mereId != null)
          ref.watch(isPremiumProvider).when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (estPremium) {
                  if (!estPremium) {
                    return const PremiumLockedCard(
                      titre: 'Suivi généalogique',
                      message:
                          "L'arbre généalogique et le coefficient de consanguinité sont réservés au plan premium.",
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Généalogie', style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 8),
                              if (oiseau.pereId != null)
                                _ParentTile(label: t?.t('father') ?? 'Père', oiseauId: oiseau.pereId!),
                              if (oiseau.mereId != null)
                                _ParentTile(label: t?.t('mother') ?? 'Mère', oiseauId: oiseau.mereId!),
                              const SizedBox(height: 8),
                              _ConsanguiniteInfo(oiseauId: oiseau.id),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _ArbreGenealogique(oiseauId: oiseau.id),
                    ],
                  );
                },
              ),

        const SizedBox(height: 16),
        _TraitementsSection(oiseauId: oiseau.id),

        if (oiseau.notes != null && oiseau.notes!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Notes', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(oiseau.notes!),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _sexeLabel(dynamic t, String sexe) {
    switch (sexe) {
      case SexeOiseau.male:
        return t?.t('male') ?? 'Mâle';
      case SexeOiseau.femelle:
        return t?.t('female') ?? 'Femelle';
      default:
        return t?.t('unknown') ?? 'Indéterminé';
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _ParentTile extends ConsumerWidget {
  final String label;
  final String oiseauId;
  const _ParentTile({required this.label, required this.oiseauId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parentAsync = ref.watch(oiseauDetailProvider(oiseauId));
    return parentAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (parent) => ListTile(
        contentPadding: EdgeInsets.zero,
        dense: true,
        leading: const Icon(Icons.arrow_upward, size: 18),
        title: Text('$label : ${parent.nomAffiche}'),
        subtitle: Text(parent.numeroBague),
        onTap: () => context.push('/oiseaux/${parent.id}'),
      ),
    );
  }
}

class _TraitementsSection extends ConsumerWidget {
  final String oiseauId;
  const _TraitementsSection({required this.oiseauId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).valueOrNull;
    final traitementsAsync = ref.watch(traitementsListProvider(oiseauId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(t?.t('treatments') ?? 'Traitements', style: Theme.of(context).textTheme.titleMedium),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: t?.t('add_treatment') ?? 'Ajouter un traitement',
                  onPressed: () => context.push('/traitements/nouveau?oiseauId=$oiseauId'),
                ),
              ],
            ),
            traitementsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, st) => Text('${t?.t('error_generic') ?? 'Erreur'}: $e'),
              data: (traitements) {
                if (traitements.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(t?.t('no_results') ?? 'Aucun résultat'),
                  );
                }
                return Column(
                  children: [
                    for (final traitement in traitements) TraitementTile(traitement: traitement),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ArbreGenealogique extends ConsumerWidget {
  final String oiseauId;
  const _ArbreGenealogique({required this.oiseauId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).valueOrNull;
    final ancetresAsync = ref.watch(ancetresProvider(oiseauId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t?.t('family_tree') ?? 'Arbre généalogique',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            ancetresAsync.when(
              loading: () => const Center(child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(),
              )),
              error: (e, st) => Text('${t?.t('error_generic') ?? 'Erreur'}: $e'),
              data: (ancetres) {
                if (ancetres.isEmpty) {
                  return Text(t?.t('no_results') ?? 'Aucun ancêtre enregistré',
                      style: TextStyle(color: Colors.grey.shade600));
                }
                final parGeneration = <int, List<OiseauAncetre>>{};
                for (final a in ancetres) {
                  parGeneration.putIfAbsent(a.generation, () => []).add(a);
                }
                final generations = parGeneration.keys.toList()..sort();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final gen in generations) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 6),
                        child: Text(
                          '${t?.t('generation') ?? 'Génération'} $gen'
                          '${gen == 1 ? ' (${t?.t('parents') ?? 'parents'})' : ''}',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final a in parGeneration[gen]!)
                            _AncetreChip(ancetre: a),
                        ],
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AncetreChip extends StatelessWidget {
  final OiseauAncetre ancetre;
  const _AncetreChip({required this.ancetre});

  @override
  Widget build(BuildContext context) {
    final estMale = ancetre.sexe == SexeOiseau.male;
    final couleur = estMale ? AppTheme.primary : AppTheme.orange;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => context.push('/oiseaux/${ancetre.id}'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: couleur.withOpacity(0.1),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: couleur.withOpacity(0.3)),
        ),
        child: Text(
          ancetre.nom != null && ancetre.nom!.trim().isNotEmpty ? ancetre.nom! : ancetre.numeroBague,
          style: TextStyle(color: couleur, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _ConsanguiniteInfo extends ConsumerWidget {
  final String oiseauId;
  const _ConsanguiniteInfo({required this.oiseauId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fAsync = ref.watch(consanguiniteProvider(oiseauId));
    final t = ref.watch(translationsProvider).valueOrNull;

    return fAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (f) {
        final niveau = f >= 0.25
            ? 'tres_eleve'
            : f >= 0.125
                ? 'eleve'
                : f >= 0.0625
                    ? 'modere'
                    : 'faible';
        final label = f >= 0.25
            ? (t?.t('risk_very_high') ?? 'Risque très élevé')
            : f >= 0.125
                ? (t?.t('risk_high') ?? 'Risque élevé')
                : f >= 0.0625
                    ? (t?.t('risk_moderate') ?? 'Risque modéré')
                    : (t?.t('risk_low') ?? 'Risque faible');
        final color = AppTheme.risqueConsanguiniteColor(niveau);

        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${t?.t('inbreeding_coefficient') ?? 'Coefficient de consanguinité'}: '
                  '${(f * 100).toStringAsFixed(1)}% — $label',
                  style: TextStyle(color: color, fontSize: 12.5),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
