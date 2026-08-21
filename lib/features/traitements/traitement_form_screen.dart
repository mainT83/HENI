import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../models/traitement.dart';
import '../../providers/traitements_provider.dart';
import '../../providers/oiseaux_provider.dart';
import '../../providers/locale_provider.dart';
import 'traitements_list_screen.dart';

class TraitementFormScreen extends ConsumerStatefulWidget {
  final String? traitementId;
  final String? oiseauIdInitial;
  const TraitementFormScreen({super.key, this.traitementId, this.oiseauIdInitial});

  bool get isEdition => traitementId != null;

  @override
  ConsumerState<TraitementFormScreen> createState() => _TraitementFormScreenState();
}

class _TraitementFormScreenState extends ConsumerState<TraitementFormScreen> {
  final _nomCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String? _oiseauId;
  String _type = TypeTraitement.vaccin;
  DateTime _dateAdministration = DateTime.now();
  DateTime? _dateRappel;

  bool _loading = false;
  bool _chargementInitial = true;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _oiseauId = widget.oiseauIdInitial;
    _chargerDonneesInitiales();
  }

  Future<void> _chargerDonneesInitiales() async {
    if (widget.isEdition) {
      final traitement = await ref.read(traitementsRepositoryProvider).fetchById(widget.traitementId!);
      _oiseauId = traitement.oiseauId;
      _type = traitement.type;
      _nomCtrl.text = traitement.nom;
      _descriptionCtrl.text = traitement.description ?? '';
      _dateAdministration = traitement.dateAdministration;
      _dateRappel = traitement.dateRappel;
      _notesCtrl.text = traitement.notes ?? '';
    }
    if (mounted) setState(() => _chargementInitial = false);
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _descriptionCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _choisirDate({required bool rappel}) async {
    final date = await showDatePicker(
      context: context,
      initialDate: (rappel ? _dateRappel : _dateAdministration) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null) return;
    setState(() {
      if (rappel) {
        _dateRappel = date;
      } else {
        _dateAdministration = date;
      }
    });
  }

  Future<void> _enregistrer() async {
    final t = ref.read(translationsProvider).valueOrNull;
    if (_oiseauId == null) {
      setState(() => _erreur = t?.t('required_field') ?? 'Veuillez choisir un oiseau');
      return;
    }
    if (_nomCtrl.text.trim().isEmpty) {
      setState(() => _erreur = t?.t('required_field') ?? 'Veuillez saisir un nom');
      return;
    }

    setState(() {
      _loading = true;
      _erreur = null;
    });

    try {
      final repo = ref.read(traitementsRepositoryProvider);

      final base = Traitement(
        id: widget.traitementId ?? const Uuid().v4(),
        eleveurId: '',
        oiseauId: _oiseauId!,
        type: _type,
        nom: _nomCtrl.text.trim(),
        description: _descriptionCtrl.text.trim().isEmpty ? null : _descriptionCtrl.text.trim(),
        dateAdministration: _dateAdministration,
        dateRappel: _dateRappel,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        createdAt: DateTime.now(),
      );

      if (widget.isEdition) {
        await repo.update(base);
      } else {
        await repo.create(base);
      }

      ref.invalidate(traitementsListProvider(null));
      ref.invalidate(traitementsListProvider(_oiseauId));
      if (widget.isEdition) ref.invalidate(traitementDetailProvider(widget.traitementId!));

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
            : (t?.t('add_treatment') ?? 'Ajouter un traitement')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _OiseauPicker(
            selectedId: _oiseauId,
            onChanged: (id) => setState(() => _oiseauId = id),
          ),
          const SizedBox(height: 12),

          DropdownButtonFormField<String>(
            value: _type,
            decoration: InputDecoration(labelText: t?.t('treatment_type') ?? 'Type'),
            items: [
              for (final type in TypeTraitement.all)
                DropdownMenuItem(value: type, child: Text(libelleTypeTraitement(type, t))),
            ],
            onChanged: (v) => setState(() => _type = v ?? TypeTraitement.vaccin),
          ),
          const SizedBox(height: 12),

          TextFormField(
            controller: _nomCtrl,
            decoration: InputDecoration(labelText: t?.t('treatment_name') ?? 'Nom du traitement'),
          ),
          const SizedBox(height: 12),

          TextFormField(
            controller: _descriptionCtrl,
            decoration: InputDecoration(labelText: t?.t('description') ?? 'Description'),
            maxLines: 2,
          ),
          const SizedBox(height: 12),

          InkWell(
            onTap: () => _choisirDate(rappel: false),
            child: InputDecorator(
              decoration: InputDecoration(labelText: t?.t('administration_date') ?? "Date d'administration"),
              child: Text(DateFormat('dd/MM/yyyy').format(_dateAdministration)),
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => _choisirDate(rappel: true),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: t?.t('reminder_date') ?? 'Date de rappel (optionnel)',
                suffixIcon: _dateRappel != null
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => setState(() => _dateRappel = null),
                      )
                    : null,
              ),
              child: Text(_dateRappel != null ? DateFormat('dd/MM/yyyy').format(_dateRappel!) : '—'),
            ),
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

class _OiseauPicker extends ConsumerWidget {
  final String? selectedId;
  final ValueChanged<String?> onChanged;
  const _OiseauPicker({required this.selectedId, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).valueOrNull;
    final oiseauxAsync = ref.watch(oiseauxListProvider);
    return oiseauxAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, st) => Text('Erreur: $e'),
      data: (oiseaux) => DropdownButtonFormField<String>(
        value: selectedId,
        decoration: InputDecoration(labelText: t?.t('bird') ?? 'Oiseau'),
        items: [
          for (final o in oiseaux) DropdownMenuItem(value: o.id, child: Text(o.nomAffiche)),
        ],
        onChanged: onChanged,
      ),
    );
  }
}
