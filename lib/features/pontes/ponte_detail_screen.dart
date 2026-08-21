import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/ponte.dart';
import '../../providers/pontes_provider.dart';
import '../../providers/locale_provider.dart';
import '../../core/theme/app_theme.dart';

class PonteDetailScreen extends ConsumerWidget {
  final String ponteId;
  const PonteDetailScreen({super.key, required this.ponteId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).valueOrNull;
    final ponteAsync = ref.watch(ponteDetailProvider(ponteId));

    return Scaffold(
      appBar: AppBar(
        title: Text(t?.t('clutches') ?? 'Ponte'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/pontes/$ponteId/modifier'),
          ),
        ],
      ),
      body: ponteAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('${t?.t('error_generic') ?? 'Erreur'}: $e')),
        data: (ponte) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Ligne(label: t?.t('lay_date') ?? 'Date de ponte', valeur: DateFormat('dd/MM/yyyy').format(ponte.datePonte)),
                    _Ligne(label: t?.t('eggs_laid') ?? "Œufs pondus", valeur: '${ponte.nombreOeufs}'),
                    _Ligne(label: t?.t('fertile_eggs') ?? 'Fécondés', valeur: '${ponte.oeufsFecondes}'),
                    _Ligne(label: t?.t('clear_eggs') ?? 'Clairs', valeur: '${ponte.oeufsClairs}'),
                    _Ligne(label: t?.t('broken_eggs') ?? 'Cassés', valeur: '${ponte.oeufsCasses}'),
                    if (ponte.dateEclosionPrevue != null)
                      _Ligne(
                        label: t?.t('expected_hatch_date') ?? 'Éclosion prévue',
                        valeur: DateFormat('dd/MM/yyyy').format(ponte.dateEclosionPrevue!),
                      ),
                    if (ponte.notes != null && ponte.notes!.isNotEmpty)
                      _Ligne(label: 'Notes', valeur: ponte.notes!),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Éclosions', style: Theme.of(context).textTheme.titleMedium),
                if (ponte.statut == StatutPonte.enCours)
                  TextButton.icon(
                    onPressed: () => _ouvrirDialogueEclosion(context, ref, ponte),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(t?.t('record_hatch') ?? 'Enregistrer'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Consumer(
              builder: (context, ref, _) {
                final eclosionsAsync = ref.watch(eclosionsProvider(ponteId));
                return eclosionsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, st) => Text('${t?.t('error_generic') ?? 'Erreur'}: $e'),
                  data: (eclosions) {
                    if (eclosions.isEmpty) {
                      return Text(t?.t('no_results') ?? 'Aucune éclosion enregistrée',
                          style: TextStyle(color: Colors.grey.shade600));
                    }
                    return Column(
                      children: [
                        for (final ec in eclosions)
                          Card(
                            child: ListTile(
                              leading: const Icon(Icons.egg_outlined, color: AppTheme.success),
                              title: Text('${ec.nombrePoussins} poussins'),
                              subtitle: Text(
                                  '${DateFormat('dd/MM/yyyy').format(ec.dateEclosion)}${ec.mortalite > 0 ? ' · ${ec.mortalite} mortalité' : ''}'),
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _ouvrirDialogueEclosion(BuildContext context, WidgetRef ref, Ponte ponte) {
    final t = ref.read(translationsProvider).valueOrNull;
    final poussinsCtrl = TextEditingController(text: '0');
    final mortaliteCtrl = TextEditingController(text: '0');
    DateTime dateEclosion = DateTime.now();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: Text(t?.t('record_hatch') ?? "Enregistrer l'éclosion"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: dialogContext,
                    initialDate: dateEclosion,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) setState(() => dateEclosion = date);
                },
                child: InputDecorator(
                  decoration: InputDecoration(labelText: t?.t('hatch_date') ?? "Date d'éclosion"),
                  child: Text(DateFormat('dd/MM/yyyy').format(dateEclosion)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: poussinsCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: t?.t('chicks_hatched') ?? 'Poussins éclos'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: mortaliteCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: t?.t('mortality') ?? 'Mortalité'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(t?.t('cancel') ?? 'Annuler'),
            ),
            FilledButton(
              onPressed: () async {
                final eclosion = Eclosion(
                  id: '',
                  eleveurId: '',
                  ponteId: ponte.id,
                  dateEclosion: dateEclosion,
                  nombrePoussins: int.tryParse(poussinsCtrl.text) ?? 0,
                  mortalite: int.tryParse(mortaliteCtrl.text) ?? 0,
                  createdAt: DateTime.now(),
                );
                await ref.read(pontesRepositoryProvider).enregistrerEclosion(eclosion);
                ref.invalidate(eclosionsProvider(ponte.id));
                ref.invalidate(ponteDetailProvider(ponte.id));
                ref.invalidate(pontesListProvider);
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              },
              child: Text(t?.t('save') ?? 'Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Ligne extends StatelessWidget {
  final String label;
  final String valeur;
  const _Ligne({required this.label, required this.valeur});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(valeur, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
