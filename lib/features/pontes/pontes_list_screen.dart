import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../models/ponte.dart';
import '../../models/oiseau.dart';
import '../../providers/pontes_provider.dart';
import '../../providers/oiseaux_provider.dart';
import '../../providers/couples_provider.dart';
import '../../providers/locale_provider.dart';
import '../../core/theme/app_theme.dart';

class PontesListScreen extends ConsumerWidget {
  const PontesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).valueOrNull;
    final pontesAsync = ref.watch(pontesListProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t?.t('clutches') ?? 'Pontes')),
      body: pontesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('${t?.t('error_generic') ?? 'Erreur'}: $e')),
        data: (pontes) {
          if (pontes.isEmpty) {
            return Center(child: Text(t?.t('no_results') ?? 'Aucun résultat'));
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(pontesListProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: pontes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) => _PonteTile(ponte: pontes[i]),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/pontes/nouvelle'),
        icon: const Icon(Icons.add),
        label: Text(t?.t('add_clutch') ?? 'Ajouter une ponte'),
      ),
    );
  }
}

class _PonteTile extends ConsumerWidget {
  final Ponte ponte;
  const _PonteTile({required this.ponte});

  Color _couleurStatut(String statut) {
    switch (statut) {
      case StatutPonte.eclos:
        return AppTheme.success;
      case StatutPonte.echec:
        return AppTheme.danger;
      default:
        return AppTheme.purple;
    }
  }

  String _libelleStatut(String statut, dynamic t) {
    switch (statut) {
      case StatutPonte.eclos:
        return t?.t('status_hatched') ?? 'Éclos';
      case StatutPonte.echec:
        return t?.t('status_failed') ?? 'Échec';
      default:
        return t?.t('status_incubating') ?? 'En cours';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).valueOrNull;
    final coupleRepo = ref.watch(couplesRepositoryProvider);
    final oiseauxRepo = ref.watch(oiseauxRepositoryProvider);
    final couleur = _couleurStatut(ponte.statut);

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(10),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: couleur.withOpacity(0.12),
          child: Icon(Icons.egg, color: couleur, size: 20),
        ),
        title: FutureBuilder(
          future: coupleRepo.fetchById(ponte.coupleId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Text('...');
            final couple = snapshot.data!;
            return FutureBuilder<List<Oiseau>>(
              future: Future.wait(
                  [oiseauxRepo.fetchById(couple.maleId), oiseauxRepo.fetchById(couple.femelleId)]),
              builder: (context, snap2) {
                if (!snap2.hasData) return const Text('...');
                final male = snap2.data![0];
                final femelle = snap2.data![1];
                return Text('${male.nomAffiche} × ${femelle.nomAffiche}',
                    style: const TextStyle(fontWeight: FontWeight.w600));
              },
            );
          },
        ),
        subtitle: Text(
            '${DateFormat('dd/MM/yyyy').format(ponte.datePonte)} · ${ponte.nombreOeufs} œufs'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: couleur.withOpacity(0.12), borderRadius: BorderRadius.circular(999)),
          child: Text(_libelleStatut(ponte.statut, t), style: TextStyle(color: couleur, fontSize: 11)),
        ),
        onTap: () => context.push('/pontes/${ponte.id}'),
      ),
    );
  }
}
