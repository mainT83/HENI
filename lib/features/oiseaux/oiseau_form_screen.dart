import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../models/oiseau.dart';
import '../../models/espece.dart';
import '../../providers/oiseaux_provider.dart';
import '../../providers/locale_provider.dart';

/// Écran unique pour créer (oiseauId == null) ou modifier un oiseau.
class OiseauFormScreen extends ConsumerStatefulWidget {
  final String? oiseauId;
  const OiseauFormScreen({super.key, this.oiseauId});

  bool get isEdition => oiseauId != null;

  @override
  ConsumerState<OiseauFormScreen> createState() => _OiseauFormScreenState();
}

class _OiseauFormScreenState extends ConsumerState<OiseauFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _bagueCtrl = TextEditingController();
  final _nomCtrl = TextEditingController();
  final _raceCtrl = TextEditingController();
  final _raceFocusNode = FocusNode();
  final _mutationCtrl = TextEditingController();
  final _origineCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String? _especeId;
  String _sexe = SexeOiseau.indetermine;
  String _statut = StatutOiseau.jeune;
  DateTime? _dateNaissance;
  String? _pereId;
  String? _mereId;

  File? _nouvellePhoto;
  String? _photoUrlExistante;

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
      final oiseau = await ref.read(oiseauxRepositoryProvider).fetchById(widget.oiseauId!);
      _bagueCtrl.text = oiseau.numeroBague;
      _nomCtrl.text = oiseau.nom ?? '';
      _raceCtrl.text = oiseau.race ?? '';
      _mutationCtrl.text = oiseau.mutation ?? '';
      _origineCtrl.text = oiseau.eleveurOrigine ?? '';
      _notesCtrl.text = oiseau.notes ?? '';
      _especeId = oiseau.especeId;
      _sexe = oiseau.sexe;
      _statut = oiseau.statut;
      _dateNaissance = oiseau.dateNaissance;
      _pereId = oiseau.pereId;
      _mereId = oiseau.mereId;
      _photoUrlExistante = oiseau.photoUrl;
    }
    if (mounted) setState(() => _chargementInitial = false);
  }

  @override
  void dispose() {
    _bagueCtrl.dispose();
    _nomCtrl.dispose();
    _raceCtrl.dispose();
    _raceFocusNode.dispose();
    _mutationCtrl.dispose();
    _origineCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _choisirPhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file != null) {
      setState(() => _nouvellePhoto = File(file.path));
    }
  }

  Future<void> _choisirDateNaissance() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateNaissance ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date != null) setState(() => _dateNaissance = date);
  }

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;
    if (_especeId == null) {
      setState(() => _erreur = 'Veuillez choisir une espèce');
      return;
    }

    setState(() {
      _loading = true;
      _erreur = null;
    });

    try {
      final repo = ref.read(oiseauxRepositoryProvider);

      final base = Oiseau(
        id: widget.oiseauId ?? const Uuid().v4(),
        eleveurId: '', // renseigné par toInsertJson()
        numeroBague: _bagueCtrl.text.trim(),
        nom: _nomCtrl.text.trim().isEmpty ? null : _nomCtrl.text.trim(),
        especeId: _especeId!,
        race: _raceCtrl.text.trim().isEmpty ? null : _raceCtrl.text.trim(),
        mutation: _mutationCtrl.text.trim().isEmpty ? null : _mutationCtrl.text.trim(),
        sexe: _sexe,
        dateNaissance: _dateNaissance,
        eleveurOrigine: _origineCtrl.text.trim().isEmpty ? null : _origineCtrl.text.trim(),
        pereId: _pereId,
        mereId: _mereId,
        statut: _statut,
        photoUrl: _photoUrlExistante,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        createdAt: DateTime.now(),
      );

      final Oiseau sauvegarde;
      if (widget.isEdition) {
        sauvegarde = await repo.update(base);
      } else {
        // On insère d'abord sans photo pour obtenir un id définitif, la
        // photo est uploadée ensuite sous ce même id.
        sauvegarde = await repo.create(base);
      }

      if (_nouvellePhoto != null) {
        final url = await repo.uploadPhoto(oiseauId: sauvegarde.id, file: _nouvellePhoto!);
        await repo.update(sauvegarde.copyWith(photoUrl: url));
      }

      ref.invalidate(oiseauxListProvider);
      if (widget.isEdition) ref.invalidate(oiseauDetailProvider(widget.oiseauId!));

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
    final especesAsync = ref.watch(especesProvider);

    if (_chargementInitial) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdition ? (t?.t('edit') ?? 'Modifier') : (t?.t('add_bird') ?? 'Ajouter un oiseau')),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: _choisirPhoto,
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: _nouvellePhoto != null
                        ? FileImage(_nouvellePhoto!)
                        : (_photoUrlExistante != null
                            ? NetworkImage(_photoUrlExistante!)
                            : null) as ImageProvider?,
                    child: (_nouvellePhoto == null && _photoUrlExistante == null)
                        ? const Icon(Icons.add_a_photo_outlined, color: Colors.grey, size: 20)
                        : null,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: TextFormField(
                    controller: _bagueCtrl,
                    decoration:
                        InputDecoration(labelText: t?.t('ring_number') ?? 'Numéro de bague', isDense: true),
                    validator: (v) => (v == null || v.trim().isEmpty) ? t?.t('required_field') : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _nomCtrl,
                    decoration: InputDecoration(labelText: t?.t('name') ?? 'Nom', isDense: true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _sexe,
                    isDense: true,
                    decoration: InputDecoration(labelText: t?.t('sex') ?? 'Sexe', isDense: true),
                    items: [
                      DropdownMenuItem(value: SexeOiseau.male, child: Text(t?.t('male') ?? 'Mâle')),
                      DropdownMenuItem(value: SexeOiseau.femelle, child: Text(t?.t('female') ?? 'Femelle')),
                      DropdownMenuItem(
                          value: SexeOiseau.indetermine, child: Text(t?.t('unknown') ?? 'Indéterminé')),
                    ],
                    onChanged: (v) => setState(() => _sexe = v ?? SexeOiseau.indetermine),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: especesAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, st) => Text('Erreur: $e'),
                    data: (especes) => DropdownButtonFormField<String>(
                      value: _especeId,
                      isDense: true,
                      decoration: InputDecoration(labelText: t?.t('species') ?? 'Espèce', isDense: true),
                      items: especes
                          .map((e) => DropdownMenuItem(value: e.id, child: Text(e.nomFr)))
                          .toList(),
                      onChanged: (v) => setState(() => _especeId = v),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ChampRace(
                    raceCtrl: _raceCtrl,
                    raceFocusNode: _raceFocusNode,
                    especeId: _especeId,
                    especes: especesAsync.valueOrNull ?? const [],
                    label: t?.t('breed') ?? 'Race',
                    dense: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _statut,
                    isDense: true,
                    decoration: InputDecoration(labelText: t?.t('status') ?? 'Statut', isDense: true),
                    items: [
                      DropdownMenuItem(
                          value: StatutOiseau.reproducteur,
                          child: Text(t?.t('status_breeder') ?? 'Reproducteur')),
                      DropdownMenuItem(
                          value: StatutOiseau.jeune, child: Text(t?.t('status_young') ?? 'Jeune')),
                      DropdownMenuItem(
                          value: StatutOiseau.aVendre, child: Text(t?.t('status_for_sale') ?? 'À vendre')),
                      DropdownMenuItem(
                          value: StatutOiseau.vendu, child: Text(t?.t('status_sold') ?? 'Vendu')),
                      DropdownMenuItem(
                          value: StatutOiseau.decede, child: Text(t?.t('status_deceased') ?? 'Décédé')),
                    ],
                    onChanged: (v) => setState(() => _statut = v ?? StatutOiseau.jeune),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: _choisirDateNaissance,
                    child: InputDecorator(
                      decoration: InputDecoration(
                          labelText: t?.t('birth_date') ?? 'Date de naissance', isDense: true),
                      child: Text(_dateNaissance != null
                          ? DateFormat('dd/MM/yyyy').format(_dateNaissance!)
                          : '—'),
                    ),
                  ),
                ),
              ],
            ),

            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 8),
                title: Text(t?.t('more_details') ?? 'Plus de détails',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                children: [
                  TextFormField(
                    controller: _mutationCtrl,
                    decoration: InputDecoration(labelText: t?.t('mutation') ?? 'Mutation', isDense: true),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _origineCtrl,
                    decoration: InputDecoration(
                        labelText: t?.t('origin_breeder') ?? "Éleveur d'origine", isDense: true),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _ParentPicker(
                          label: t?.t('father') ?? 'Père',
                          sexe: SexeOiseau.male,
                          selectedId: _pereId,
                          onChanged: (id) => setState(() => _pereId = id),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ParentPicker(
                          label: t?.t('mother') ?? 'Mère',
                          sexe: SexeOiseau.femelle,
                          selectedId: _mereId,
                          onChanged: (id) => setState(() => _mereId = id),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _notesCtrl,
                    decoration: const InputDecoration(labelText: 'Notes', isDense: true),
                    maxLines: 2,
                  ),
                ],
              ),
            ),

            if (_erreur != null) ...[
              const SizedBox(height: 8),
              Text(_erreur!, style: const TextStyle(color: Colors.red)),
            ],

            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loading ? null : _enregistrer,
              child: _loading
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(t?.t('save') ?? 'Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Champ "race" : texte libre, sauf pour les espèces qui ont une liste de
/// référence connue (canari, chardonneret, perruche ondulée) où c'est une
/// autocomplétion — toujours modifiable en texte libre si la race cherchée
/// n'y figure pas.
class _ChampRace extends ConsumerWidget {
  final TextEditingController raceCtrl;
  final FocusNode raceFocusNode;
  final String? especeId;
  final List<Espece> especes;
  final String label;
  final bool dense;

  const _ChampRace({
    required this.raceCtrl,
    required this.raceFocusNode,
    required this.especeId,
    required this.especes,
    required this.label,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final espece = especes.where((e) => e.id == especeId);
    final code = espece.isNotEmpty ? espece.first.code : null;
    final categorie = espece.isNotEmpty ? espece.first.categorie : null;

    List<String> suggestions = const [];
    String? aide;

    if (categorie == 'canari') {
      suggestions = (ref.watch(racesCanariProvider).valueOrNull ?? const []).map((r) => r.nom).toList();
      aide = 'Chant · Couleur · Posture';
    } else if (categorie == 'chardonneret') {
      suggestions = ref.watch(racesChardonneretProvider).valueOrNull ?? const [];
      aide = 'Mutations couleur';
    } else if (code == 'perruche_ondulee') {
      final paires = ref.watch(racesPerrucheOnduleeProvider).valueOrNull ?? const [];
      suggestions = paires.map((p) => p.value).toSet().toList();
      aide = 'Posture · Couleur';
    }

    if (suggestions.isEmpty) {
      return TextFormField(
        controller: raceCtrl,
        focusNode: raceFocusNode,
        decoration: InputDecoration(labelText: label, isDense: dense),
      );
    }

    return Autocomplete<String>(
      textEditingController: raceCtrl,
      focusNode: raceFocusNode,
      optionsBuilder: (valeur) {
        if (valeur.text.trim().isEmpty) return suggestions;
        final q = valeur.text.toLowerCase();
        return suggestions.where((s) => s.toLowerCase().contains(q));
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(labelText: label, helperText: dense ? null : aide, isDense: dense),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        final liste = options.toList();
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280, maxWidth: 340),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: liste.length,
                itemBuilder: (context, i) => ListTile(
                  dense: true,
                  title: Text(liste[i]),
                  onTap: () => onSelected(liste[i]),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ParentPicker extends ConsumerWidget {
  final String label;
  final String sexe;
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  const _ParentPicker({
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
          isDense: true,
          decoration: InputDecoration(labelText: label, isDense: true),
          items: [
            const DropdownMenuItem(value: null, child: Text('—')),
            ...oiseaux.map(
              (o) => DropdownMenuItem(value: o.id, child: Text('${o.numeroBague} — ${o.nomAffiche}')),
            ),
          ],
          onChanged: onChanged,
        );
      },
    );
  }
}
