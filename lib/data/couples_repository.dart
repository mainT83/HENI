import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/couple.dart';

/// Levée quand le trigger `verifier_limite_couples_gratuit` bloque la
/// création faute d'être passé en premium (voir migration 011).
class LimitePlanGratuitException implements Exception {}

class CouplesRepository {
  final SupabaseClient _client;
  CouplesRepository(this._client);

  String get _eleveurId => _client.auth.currentUser!.id;

  Future<List<Couple>> fetchAll() async {
    final rows = await _client
        .from('couples')
        .select()
        .eq('eleveur_id', _eleveurId)
        .order('created_at', ascending: false);
    return (rows as List).map((r) => Couple.fromJson(r as Map<String, dynamic>)).toList();
  }

  Future<Couple> fetchById(String id) async {
    final row = await _client.from('couples').select().eq('id', id).single();
    return Couple.fromJson(row);
  }

  Future<Couple> create(Couple couple) async {
    try {
      final row = await _client
          .from('couples')
          .insert(couple.toInsertJson(eleveurId: _eleveurId))
          .select()
          .single();
      return Couple.fromJson(row);
    } on PostgrestException catch (e) {
      if (e.message.contains('limite_plan_gratuit')) {
        throw LimitePlanGratuitException();
      }
      rethrow;
    }
  }

  Future<Couple> update(Couple couple) async {
    final row = await _client
        .from('couples')
        .update(couple.toInsertJson(eleveurId: _eleveurId))
        .eq('id', couple.id)
        .select()
        .single();
    return Couple.fromJson(row);
  }

  Future<void> delete(String id) async {
    await _client.from('couples').delete().eq('id', id);
  }
}
