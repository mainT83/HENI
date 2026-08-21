import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../models/couple.dart';
import '../../models/oiseau.dart';
import '../../providers/couples_provider.dart';
import '../../providers/oiseaux_provider.dart';
import '../../providers/locale_provider.dart';
import '../../core/theme/app_theme.dart';

class CouplesListScreen extends ConsumerWidget {
  const CouplesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).valueOrNull;
    final couplesAsync = ref.watch(couplesListProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t?.t('couples') ?? 'Couples')),
      body: couplesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('${t?.t('error_generic') ?? 'Erreur'}: $e')),
        data: (couples) {
          if (couples.isEmpty) {
            return Center(child: Text(t?.t('no_results') ?? 'Aucun résultat'));
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(couplesListProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: couples.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) => _CoupleTile(couple: couples[i]),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/couples/nouveau'),
        icon: const Icon(Icons.add),
        label: Text(t?.t('add_couple') ?? 'Ajouter un couple'),
      ),
    );
  }
}

class _CoupleTile extends ConsumerWidget {
  final Couple couple;
  const _CoupleTile({required this.couple});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).valueOrNull;
    final repo = ref.watch(oiseauxRepositoryProvider);

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(10),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: couple.actif
              ? AppTheme.success.withOpacity(0.12)
              : Colors.grey.shade200,
          child: Icon(Icons.favorite,
              color: couple.actif ? AppTheme.success : Colors.grey, size: 20),
        ),
        title: FutureBuilder<List<Oiseau>>(
          future: Future.wait([repo.fetchById(couple.maleId), repo.fetchById(couple.femelleId)]),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Text('...');
            final male = snapshot.data![0];
            final femelle = snapshot.data![1];
            return Text('${male.nomAffiche} × ${femelle.nomAffiche}',
                style: const TextStyle(fontWeight: FontWeight.w600));
          },
        ),
        subtitle: Text(DateFormat('dd/MM/yyyy').format(couple.dateFormation)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: (couple.actif ? AppTheme.success : Colors.grey).withOpacity(0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            couple.actif ? (t?.t('active') ?? 'Actif') : (t?.t('inactive') ?? 'Inactif'),
            style: TextStyle(
                color: couple.actif ? AppTheme.success : Colors.grey.shade700, fontSize: 11),
          ),
        ),
        onTap: () => context.push('/couples/${couple.id}/modifier'),
      ),
    );
  }
}
