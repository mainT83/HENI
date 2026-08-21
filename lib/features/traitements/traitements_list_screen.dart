import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../models/traitement.dart';
import '../../providers/traitements_provider.dart';
import '../../providers/oiseaux_provider.dart';
import '../../providers/locale_provider.dart';
import '../../core/theme/app_theme.dart';

class TraitementsListScreen extends ConsumerWidget {
  const TraitementsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).valueOrNull;
    final traitementsAsync = ref.watch(traitementsListProvider(null));

    return Scaffold(
      appBar: AppBar(title: Text(t?.t('treatments') ?? 'Traitements')),
      body: traitementsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('${t?.t('error_generic') ?? 'Erreur'}: $e')),
        data: (traitements) {
          if (traitements.isEmpty) {
            return Center(child: Text(t?.t('no_results') ?? 'Aucun résultat'));
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(traitementsListProvider(null).notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: traitements.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) => TraitementTile(traitement: traitements[i], afficherOiseau: true),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/traitements/nouveau'),
        icon: const Icon(Icons.add),
        label: Text(t?.t('add_treatment') ?? 'Ajouter un traitement'),
      ),
    );
  }
}

IconData iconePourTypeTraitement(String type) {
  switch (type) {
    case TypeTraitement.vaccin:
      return Icons.vaccines;
    case TypeTraitement.vermifuge:
    case TypeTraitement.antiparasitaire:
      return Icons.bug_report;
    case TypeTraitement.antibiotique:
      return Icons.medication;
    case TypeTraitement.vitamine:
      return Icons.local_pharmacy;
    default:
      return Icons.healing;
  }
}

String libelleTypeTraitement(String type, dynamic t) {
  switch (type) {
    case TypeTraitement.vaccin:
      return t?.t('treatment_type_vaccine') ?? 'Vaccin';
    case TypeTraitement.vermifuge:
      return t?.t('treatment_type_dewormer') ?? 'Vermifuge';
    case TypeTraitement.antiparasitaire:
      return t?.t('treatment_type_antiparasitic') ?? 'Antiparasitaire';
    case TypeTraitement.antibiotique:
      return t?.t('treatment_type_antibiotic') ?? 'Antibiotique';
    case TypeTraitement.vitamine:
      return t?.t('treatment_type_vitamin') ?? 'Vitamine';
    default:
      return t?.t('treatment_type_other') ?? 'Autre';
  }
}

class TraitementTile extends ConsumerWidget {
  final Traitement traitement;
  final bool afficherOiseau;
  const TraitementTile({super.key, required this.traitement, this.afficherOiseau = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).valueOrNull;
    final rappelProche = traitement.dateRappel != null &&
        !traitement.dateRappel!.isAfter(DateTime.now().add(const Duration(days: 7)));

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(10),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: AppTheme.primary.withOpacity(0.12),
          child: Icon(iconePourTypeTraitement(traitement.type), color: AppTheme.primary, size: 20),
        ),
        title: Text(traitement.nom, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (afficherOiseau)
              FutureBuilder(
                future: ref.watch(oiseauxRepositoryProvider).fetchById(traitement.oiseauId),
                builder: (context, snapshot) =>
                    Text(snapshot.hasData ? snapshot.data!.nomAffiche : '...'),
              ),
            Text(
                '${libelleTypeTraitement(traitement.type, t)} · ${DateFormat('dd/MM/yyyy').format(traitement.dateAdministration)}'),
            if (traitement.dateRappel != null)
              Text(
                '${t?.t('reminder') ?? 'Rappel'} : ${DateFormat('dd/MM/yyyy').format(traitement.dateRappel!)}',
                style: TextStyle(
                  color: rappelProche ? AppTheme.danger : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: rappelProche ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
          ],
        ),
        isThreeLine: true,
        onTap: () => context.push('/traitements/${traitement.id}/modifier'),
      ),
    );
  }
}
