import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/traitement.dart';

class TraitementsRepository {
  final SupabaseClient _client;
  TraitementsRepository(this._client);

  Future<List<Traitement>> fetchAll({String? oiseauId}) async {
    var query = _client.from('traitements').select().eq('eleveur_id', _client.auth.currentUser!.id);
    if (oiseauId != null) {
      query = query.eq('oiseau_id', oiseauId);
    }
    final rows = await query.order('date_administration', ascending: false);
    return (rows as List).map((r) => Traitement.fromJson(r as Map<String, dynamic>)).toList();
  }

  Future<Traitement> fetchById(String id) async {
    final row = await _client.from('traitements').select().eq('id', id).single();
    return Traitement.fromJson(row);
  }

  Future<Traitement> create(Traitement traitement) async {
    final row = await _client
        .from('traitements')
        .insert(traitement.toInsertJson(oiseauId: traitement.oiseauId))
        .select()
        .single();
    return Traitement.fromJson(row);
  }

  Future<Traitement> update(Traitement traitement) async {
    final row = await _client
        .from('traitements')
        .update(traitement.toInsertJson(oiseauId: traitement.oiseauId))
        .eq('id', traitement.id)
        .select()
        .single();
    return Traitement.fromJson(row);
  }

  Future<void> delete(String id) async {
    await _client.from('traitements').delete().eq('id', id);
  }
}
