import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../models/couple.dart';
import '../../models/oiseau.dart';
import '../../providers/couples_provider.dart';
import '../../providers/oiseaux_provider.dart';
import '../../providers/locale_provider.dart';
import '../../data/oiseaux_repository.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/premium_locked_card.dart';

/// Écran unique pour créer (coupleId == null) ou modifier un couple.
class CoupleFormScreen extends ConsumerStatefulWidget {
  final String? coupleId;
  const CoupleFormScreen({super.key, this.coupleId});

  bool get isEdition => coupleId != null;

  @override
  ConsumerState<CoupleFormScreen> createState() => _CoupleFormScreenState();
}

class _CoupleFormScreenState extends ConsumerState<CoupleFormScreen> {
  final _notesCtrl = TextEditingController();

  String? _maleId;
  String? _femelleId;
  DateTime _dateFormation = DateTime.now();
  bool _actif = true;

  bool _loading = false;
  bool _chargementInitial = true;
  String? _erreur;

  RisqueConsanguinite? _risque;
  bool _chargementRisque = false;

  @override
  void initState() {
    super.initState();
    _chargerDonneesInitiales();
  }

  Future<void> _chargerDonneesInitiales() async {
    if (widget.isEdition) {
      final couple = await ref.read(couplesRepositoryProvider).fetchById(widget.coupleId!);
      _maleId = couple.maleId;
      _femelleId = couple.femelleId;
      _dateFormation = couple.dateFormation;
      _actif = couple.actif;
      _notesCtrl.text = couple.notes ?? '';
    }
    if (mounted) setState(() => _chargementInitial = false);
    await _rafraichirRisque();
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _rafraichirRisque() async {
    if (_maleId == null || _femelleId == null) {
      setState(() => _risque = null);
      return;
    }
    setState(() => _chargementRisque = true);
    try {
      final risque = await ref
          .read(oiseauxRepositoryProvider)
          .risqueCroisement(pereId: _maleId!, mereId: _femelleId!);
      if (mounted) setState(() => _risque = risque);
    } catch (_) {
      if (mounted) setState(() => _risque = null);
    } finally {
      if (mounted) setState(() => _chargementRisque = false);
    }
  }

  Future<void> _choisirDateFormation() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateFormation,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date != null) setState(() => _dateFormation = date);
  }

  Future<void> _enregistrer() async {
    final t = ref.read(translationsProvider).valueOrNull;

    if (_maleId == null || _femelleId == null) {
      setState(() => _erreur = t?.t('required_field') ?? 'Veuillez choisir le mâle et la femelle');
      return;
    }

    setState(() {
      _loading = true;
      _erreur = null;
    });

    try {
      final repo = ref.read(couplesRepositoryProvider);

      final base = Couple(
        id: widget.coupleId ?? const Uuid().v4(),
        eleveurId: '', // renseigné par toInsertJson()
        maleId: _maleId!,
        femelleId: _femelleId!,
        dateFormation: _dateFormation,
        actif: _actif,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        createdAt: DateTime.now(),
      );

      if (widget.isEdition) {
        await repo.update(base);
      } else {
        await repo.create(base);
      }

      ref.invalidate(couplesListProvider);
      if (widget.isEdition) ref.invalidate(coupleDetailProvider(widget.coupleId!));

      if (mounted) context.pop();
    } catch (e) {
      setState(() => _erreur = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider).valueOrNull;

    if (_chargementInitial) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdition
            ? (t?.t('edit') ?? 'Modifier')
            : (t?.t('add_couple') ?? 'Ajouter un couple')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ReproducteurPicker(
            label: t?.t('father') ?? 'Mâle',
            sexe: SexeOiseau.male,
            selectedId: _maleId,
            onChanged: (id) {
              setState(() => _maleId = id);
              _rafraichirRisque();
            },
          ),
          const SizedBox(height: 12),
          _ReproducteurPicker(
            label: t?.t('mother') ?? 'Femelle',
            sexe: SexeOiseau.femelle,
            selectedId: _femelleId,
            onChanged: (id) {
              setState(() => _femelleId = id);
              _rafraichirRisque();
            },
          ),
          const SizedBox(height: 12),

          if (_maleId != null && _femelleId != null)
            ref.watch(isPremiumProvider).when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (estPremium) {
                    if (!estPremium) {
                      return const PremiumLockedCard(
                        titre: 'Coefficient de consanguinité',
                        message: 'Le contrôle automatique du risque de consanguinité est réservé au plan premium.',
                      );
                    }
                    if (_chargementRisque) return const LinearProgressIndicator();
                    if (_risque != null) return _RisqueBanner(risque: _risque!, t: t);
                    return const SizedBox.shrink();
                  },
                ),

          const SizedBox(height: 12),
          InkWell(
            onTap: _choisirDateFormation,
            child: InputDecorator(
              decoration: InputDecoration(labelText: t?.t('formation_date') ?? 'Date de formation'),
              child: Text(DateFormat('dd/MM/yyyy').format(_dateFormation)),
            ),
          ),
          const SizedBox(height: 12),

          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(t?.t('active') ?? 'Actif'),
            value: _actif,
            onChanged: (v) => setState(() => _actif = v),
          ),
          const SizedBox(height: 4),

          TextFormField(
            controller: _notesCtrl,
            decoration: InputDecoration(labelText: t?.t('notes') ?? 'Notes'),
            maxLines: 3,
          ),

          if (_erreur != null) ...[
            const SizedBox(height: 12),
            Text(_erreur!, style: const TextStyle(color: Colors.red)),
          ],

          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loading ? null : _enregistrer,
            child: _loading
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(t?.t('save') ?? 'Enregistrer'),
          ),
        ],
      ),
    );
  }
}

class _ReproducteurPicker extends ConsumerWidget {
  final String label;
  final String sexe;
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  const _ReproducteurPicker({
    required this.label,
    required this.sexe,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(oiseauxRepositoryProvider);
    return FutureBuilder<List<Oiseau>>(
      future: repo.fetchReproducteurs(sexe: sexe),
      builder: (context, snapshot) {
        final oiseaux = snapshot.data ?? [];
        return DropdownButtonFormField<String>(
          value: selectedId,
          decoration: InputDecoration(labelText: label),
          items: oiseaux
              .map((o) => DropdownMenuItem(value: o.id, child: Text('${o.numeroBague} — ${o.nomAffiche}')))
              .toList(),
          onChanged: onChanged,
        );
      },
    );
  }
}

class _RisqueBanner extends StatelessWidget {
  final RisqueConsanguinite risque;
  final dynamic t;
  const _RisqueBanner({required this.risque, required this.t});

  String _label() {
    switch (risque.niveau) {
      case 'tres_eleve':
        return t?.t('risk_very_high') ?? 'Risque très élevé - déconseillé';
      case 'eleve':
        return t?.t('risk_high') ?? 'Risque élevé';
      case 'modere':
        return t?.t('risk_moderate') ?? 'Risque modéré';
      default:
        return t?.t('risk_low') ?? 'Risque faible';
    }
  }

  @override
  Widget build(BuildContext context) {
    final couleur = AppTheme.risqueConsanguiniteColor(risque.niveau);
    final pct = (risque.coefficient * 100).toStringAsFixed(1);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: couleur.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: couleur.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: couleur, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${t?.t('inbreeding_coefficient') ?? 'Coefficient de consanguinité'}: $pct% — ${_label()}',
              style: TextStyle(color: couleur, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
