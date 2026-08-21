import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/oiseau.dart';

class OiseauAncetre {
  final String id;
  final int generation;
  final String numeroBague;
  final String? nom;
  final String sexe;
  final String? photoUrl;

  OiseauAncetre.fromJson(Map<String, dynamic> json)
      : id = json['ancetre_id'] as String,
        generation = json['generation'] as int,
        numeroBague = json['numero_bague'] as String,
        nom = json['nom'] as String?,
        sexe = json['sexe'] as String,
        photoUrl = json['photo_url'] as String?;
}

class RisqueConsanguinite {
  final double coefficient;
  final String niveau; // faible | modere | eleve | tres_eleve

  RisqueConsanguinite.fromJson(Map<String, dynamic> json)
      : coefficient = (json['coefficient'] as num).toDouble(),
        niveau = json['niveau'] as String;
}

class OiseauxRepository {
  final SupabaseClient _client;
  OiseauxRepository(this._client);

  String get _eleveurId => _client.auth.currentUser!.id;

  Future<List<Oiseau>> fetchAll({String? statut, String? recherche}) async {
    var query = _client.from('oiseaux').select().eq('eleveur_id', _eleveurId);
    if (statut != null) {
      query = query.eq('statut', statut);
    }
    if (recherche != null && recherche.trim().isNotEmpty) {
      query = query.or('numero_bague.ilike.%$recherche%,nom.ilike.%$recherche%');
    }
    final rows = await query.order('created_at', ascending: false);
    return (rows as List).map((r) => Oiseau.fromJson(r as Map<String, dynamic>)).toList();
  }

  Future<Oiseau> fetchById(String id) async {
    final row = await _client.from('oiseaux').select().eq('id', id).single();
    return Oiseau.fromJson(row);
  }

  /// Reproducteurs disponibles pour être désignés comme père/mère (filtrés
  /// par sexe côté client pour affichage, la contrainte est aussi vérifiée
  /// côté base par le trigger valider_parents_oiseau).
  Future<List<Oiseau>> fetchReproducteurs({required String sexe}) async {
    final rows = await _client
        .from('oiseaux')
        .select()
        .eq('eleveur_id', _eleveurId)
        .eq('sexe', sexe)
        .order('numero_bague');
    return (rows as List).map((r) => Oiseau.fromJson(r as Map<String, dynamic>)).toList();
  }

  Future<Oiseau> create(Oiseau oiseau) async {
    final row = await _client
        .from('oiseaux')
        .insert(oiseau.toInsertJson(eleveurId: _eleveurId))
        .select()
        .single();
    return Oiseau.fromJson(row);
  }

  Future<Oiseau> update(Oiseau oiseau) async {
    final row = await _client
        .from('oiseaux')
        .update(oiseau.toInsertJson(eleveurId: _eleveurId))
        .eq('id', oiseau.id)
        .select()
        .single();
    return Oiseau.fromJson(row);
  }

  Future<void> delete(String id) async {
    await _client.from('oiseaux').delete().eq('id', id);
  }

  /// Upload une photo dans le bucket "photos-oiseaux" sous {eleveur_id}/{oiseau_id}.jpg
  /// et retourne l'URL publique.
  Future<String> uploadPhoto({required String oiseauId, required File file}) async {
    final path = '$_eleveurId/$oiseauId.jpg';
    await _client.storage.from('photos-oiseaux').upload(
          path,
          file,
          fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
        );
    return _client.storage.from('photos-oiseaux').getPublicUrl(path);
  }

  // ---------------------------------------------------------------------
  // Généalogie
  // ---------------------------------------------------------------------

  Future<List<OiseauAncetre>> ancetres(String oiseauId, {int profondeur = 6}) async {
    final rows = await _client.rpc('ancetres', params: {
      'p_oiseau_id': oiseauId,
      'p_profondeur': profondeur,
    });
    return (rows as List).map((r) => OiseauAncetre.fromJson(r as Map<String, dynamic>)).toList();
  }

  Future<List<OiseauAncetre>> descendants(String oiseauId, {int profondeur = 6}) async {
    final rows = await _client.rpc('descendants', params: {
      'p_oiseau_id': oiseauId,
      'p_profondeur': profondeur,
    });
    // Les colonnes renvoyées sont descendant_id/generation/... : on les
    // remappe sur la même forme que OiseauAncetre (id + generation + détail).
    return (rows as List).map((r) {
      final m = Map<String, dynamic>.from(r as Map);
      m['ancetre_id'] = m['descendant_id'];
      return OiseauAncetre.fromJson(m);
    }).toList();
  }

  Future<double> consanguiniteOiseau(String oiseauId) async {
    final result = await _client.rpc('consanguinite_oiseau', params: {'p_oiseau_id': oiseauId});
    if (result == null) return 0.0;
    return (result as num).toDouble();
  }

  /// À appeler avant de créer un couple, pour avertir l'éleveur du risque.
  Future<RisqueConsanguinite> risqueCroisement({
    required String pereId,
    required String mereId,
  }) async {
    final rows = await _client.rpc('niveau_risque_consanguinite', params: {
      'p_pere_id': pereId,
      'p_mere_id': mereId,
    });
    final row = (rows as List).first as Map<String, dynamic>;
    return RisqueConsanguinite.fromJson(row);
  }
}
