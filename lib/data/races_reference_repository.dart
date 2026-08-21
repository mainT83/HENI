import 'package:supabase_flutter/supabase_flutter.dart';

/// Dépôt générique pour les listes de référence "race/mutation" à plat
/// (juste un nom), comme races_chardonneret.
class RacesSimpleRepository {
  final SupabaseClient _client;
  final String table;
  RacesSimpleRepository(this._client, this.table);

  Future<List<String>> fetchAll() async {
    final rows = await _client.from(table).select('nom').order('nom');
    return (rows as List).map((r) => (r as Map<String, dynamic>)['nom'] as String).toList();
  }
}

/// Dépôt pour les listes de référence "race/mutation" groupées par
/// catégorie (categorie, nom), comme races_perruche_ondulee.
class RacesCategoriseesRepository {
  final SupabaseClient _client;
  final String table;
  RacesCategoriseesRepository(this._client, this.table);

  Future<List<MapEntry<String, String>>> fetchAll() async {
    final rows = await _client.from(table).select('categorie, nom').order('categorie').order('nom');
    return (rows as List)
        .map((r) => MapEntry((r as Map<String, dynamic>)['categorie'] as String, r['nom'] as String))
        .toList();
  }
}
