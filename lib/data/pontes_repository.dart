import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ponte.dart';

class PontesRepository {
  final SupabaseClient _client;
  PontesRepository(this._client);

  String get _eleveurId => _client.auth.currentUser!.id;

  Future<List<Ponte>> fetchAll({String? coupleId}) async {
    var query = _client.from('pontes').select().eq('eleveur_id', _eleveurId);
    if (coupleId != null) {
      query = query.eq('couple_id', coupleId);
    }
    final rows = await query.order('date_ponte', ascending: false);
    return (rows as List).map((r) => Ponte.fromJson(r as Map<String, dynamic>)).toList();
  }

  Future<Ponte> fetchById(String id) async {
    final row = await _client.from('pontes').select().eq('id', id).single();
    return Ponte.fromJson(row);
  }

  Future<Ponte> create(Ponte ponte) async {
    final row = await _client
        .from('pontes')
        .insert(ponte.toInsertJson(eleveurId: _eleveurId))
        .select()
        .single();
    return Ponte.fromJson(row);
  }

  Future<Ponte> update(Ponte ponte) async {
    final row = await _client
        .from('pontes')
        .update(ponte.toInsertJson(eleveurId: _eleveurId))
        .eq('id', ponte.id)
        .select()
        .single();
    return Ponte.fromJson(row);
  }

  Future<void> delete(String id) async {
    await _client.from('pontes').delete().eq('id', id);
  }

  Future<List<Eclosion>> fetchEclosions(String ponteId) async {
    final rows = await _client
        .from('eclosions')
        .select()
        .eq('ponte_id', ponteId)
        .order('date_eclosion');
    return (rows as List).map((r) => Eclosion.fromJson(r as Map<String, dynamic>)).toList();
  }

  /// Enregistre un résultat d'éclosion — la base marque automatiquement la
  /// ponte comme "eclos" (trigger marquer_ponte_eclose).
  Future<Eclosion> enregistrerEclosion(Eclosion eclosion) async {
    final row = await _client.from('eclosions').insert(eclosion.toInsertJson()).select().single();
    return Eclosion.fromJson(row);
  }
}
