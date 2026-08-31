import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../models/ponte.dart';
import '../../models/couple.dart';
import '../../providers/pontes_provider.dart';
import '../../providers/couples_provider.dart';
import '../../providers/oiseaux_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/dashboard_provider.dart';

class PonteFormScreen extends ConsumerStatefulWidget {
  final String? ponteId;
  const PonteFormScreen({super.key, this.ponteId});

  bool get isEdition => ponteId != null;

  @override
  ConsumerState<PonteFormScreen> createState() => _PonteFormScreenState();
}

class _PonteFormScreenState extends ConsumerState<PonteFormScreen> {
  final _nombreOeufsCtrl = TextEditingController(text: '0');
  final _oeufsFecondesCtrl = TextEditingController(text: '0');
  final _oeufsClairsCtrl = TextEditingController(text: '0');
  final _oeufsCassesCtrl = TextEditingController(text: '0');
  final _notesCtrl = TextEditingController();

  String? _coupleId;
  DateTime _datePonte = DateTime.now();
  DateTime? _dateEclosionPrevue;
  String _statut = StatutPonte.enCours;

  bool _loading = false;
  bool _chargementInitial = true;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _chargerDonneesInitiales();
  }

  Future<void> _chargerDonneesInitiales() async {
    if (widget.isEdition) {
      final ponte = await ref.read(pontesRepositoryProvider).fetchById(widget.ponteId!);
      _coupleId = ponte.coupleId;
      _datePonte = ponte.datePonte;
      _dateEclosionPrevue = ponte.dateEclosionPrevue;
      _statut = ponte.statut;
      _nombreOeufsCtrl.text = '${ponte.nombreOeufs}';
      _oeufsFecondesCtrl.text = '${ponte.oeufsFecondes}';
      _oeufsClairsCtrl.text = '${ponte.oeufsClairs}';
      _oeufsCassesCtrl.text = '${ponte.oeufsCasses}';
      _notesCtrl.text = ponte.notes ?? '';
    }
    if (mounted) setState(() => _chargementInitial = false);
  }

  @override
  void dispose() {
    _nombreOeufsCtrl.dispose();
    _oeufsFecondesCtrl.dispose();
    _oeufsClairsCtrl.dispose();
    _oeufsCassesCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _choisirDate({required bool prevue}) async {
    final date = await showDatePicker(
      context: context,
      initialDate: (prevue ? _dateEclosionPrevue : _datePonte) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null) return;
    setState(() {
      if (prevue) {
        _dateEclosionPrevue = date;
      } else {
        _datePonte = date;
      }
    });
    if (!prevue) _recalculerDateEclosionPrevue();
  }

  /// Pré-calcule automatiquement la date d'éclosion prévue à partir de la
  /// durée d'incubation de l'espèce du couple (date_ponte + durée). L'éleveur
  /// peut toujours la corriger manuellement ensuite via le sélecteur de date.
  Future<void> _recalculerDateEclosionPrevue() async {
    if (_coupleId == null) return;
    try {
      final couple = await ref.read(couplesRepositoryProvider).fetchById(_coupleId!);
      final male = await ref.read(oiseauxRepositoryProvider).fetchById(couple.maleId);
      final especes = await ref.read(especesRepositoryProvider).fetchAll();
      final espece = especes.where((e) => e.id == male.especeId);
      if (espece.isEmpty) return;
      final duree = espece.first.dureeIncubationJours;
      if (duree == null) return;
      if (!mounted) return;
      setState(() => _dateEclosionPrevue = _datePonte.add(Duration(days: duree)));
    } catch (_) {
      // Espèce/couple pas encore résolu (ex: en cours de chargement) : on
      // laisse l'éleveur saisir la date manuellement dans ce cas.
    }
  }

  Future<void> _enregistrer() async {
    final t = ref.read(translationsProvider).valueOrNull;
    if (_coupleId == null) {
      setState(() => _erreur = t?.t('required_field') ?? 'Veuillez choisir un couple');
      return;
    }

    setState(() {
      _loading = true;
      _erreur = null;
    });

    try {
      final repo = ref.read(pontesRepositoryProvider);

      final base = Ponte(
        id: widget.ponteId ?? const Uuid().v4(),
        eleveurId: '',
        coupleId: _coupleId!,
        datePonte: _datePonte,
        nombreOeufs: int.tryParse(_nombreOeufsCtrl.text) ?? 0,
        dateEclosionPrevue: _dateEclosionPrevue,
        oeufsFecondes: int.tryParse(_oeufsFecondesCtrl.text) ?? 0,
        oeufsClairs: int.tryParse(_oeufsClairsCtrl.text) ?? 0,
        oeufsCasses: int.tryParse(_oeufsCassesCtrl.text) ?? 0,
        statut: _statut,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        createdAt: DateTime.now(),
      );

      if (widget.isEdition) {
        await repo.update(base);
      } else {
        await repo.create(base);
      }

      ref.invalidate(pontesListProvider);
      if (widget.isEdition) ref.invalidate(ponteDetailProvider(widget.ponteId!));
      ref.invalidate(dashboardStatsProvider);
      ref.invalidate(incubationsActivesProvider);

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
            : (t?.t('add_clutch') ?? 'Ajouter une ponte')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _CouplePicker(
            selectedId: _coupleId,
            onChanged: (id) {
              setState(() => _coupleId = id);
              _recalculerDateEclosionPrevue();
            },
          ),
          const SizedBox(height: 12),

          InkWell(
            onTap: () => _choisirDate(prevue: false),
            child: InputDecorator(
              decoration: InputDecoration(labelText: t?.t('lay_date') ?? 'Date de ponte'),
              child: Text(DateFormat('dd/MM/yyyy').format(_datePonte)),
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => _choisirDate(prevue: true),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: t?.t('expected_hatch_date') ?? 'Éclosion prévue',
                helperText: t?.t('auto_calculated_editable') ?? 'Calculé automatiquement, modifiable',
              ),
              child: Text(_dateEclosionPrevue != null
                  ? DateFormat('dd/MM/yyyy').format(_dateEclosionPrevue!)
                  : '—'),
            ),
          ),
          const SizedBox(height: 12),

          TextFormField(
            controller: _nombreOeufsCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: t?.t('eggs_laid') ?? "Nombre d'œufs"),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _oeufsFecondesCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: t?.t('fertile_eggs') ?? 'Fécondés'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _oeufsClairsCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: t?.t('clear_eggs') ?? 'Clairs'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _oeufsCassesCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: t?.t('broken_eggs') ?? 'Cassés'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          DropdownButtonFormField<String>(
            value: _statut,
            decoration: InputDecoration(labelText: t?.t('status') ?? 'Statut'),
            items: [
              DropdownMenuItem(value: StatutPonte.enCours, child: Text(t?.t('status_incubating') ?? 'En cours')),
              DropdownMenuItem(value: StatutPonte.eclos, child: Text(t?.t('status_hatched') ?? 'Éclos')),
              DropdownMenuItem(value: StatutPonte.echec, child: Text(t?.t('status_failed') ?? 'Échec')),
            ],
            onChanged: (v) => setState(() => _statut = v ?? StatutPonte.enCours),
          ),
          const SizedBox(height: 12),

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

class _CouplePicker extends ConsumerWidget {
  final String? selectedId;
  final ValueChanged<String?> onChanged;
  const _CouplePicker({required this.selectedId, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).valueOrNull;
    final couplesAsync = ref.watch(couplesListProvider);
    return couplesAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, st) => Text('Erreur: $e'),
      data: (couples) => DropdownButtonFormField<String>(
        value: selectedId,
        decoration: InputDecoration(labelText: t?.t('pair') ?? 'Couple'),
        items: [
          for (final c in couples) DropdownMenuItem(value: c.id, child: _CoupleLabel(couple: c)),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

class _CoupleLabel extends ConsumerWidget {
  final Couple couple;
  const _CoupleLabel({required this.couple});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(oiseauxRepositoryProvider);
    return FutureBuilder(
      future: Future.wait([repo.fetchById(couple.maleId), repo.fetchById(couple.femelleId)]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Text('...');
        final male = snapshot.data![0];
        final femelle = snapshot.data![1];
        return Text('${male.nomAffiche} × ${femelle.nomAffiche}');
      },
    );
  }
}
