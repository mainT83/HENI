import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/race_canari.dart';

class RacesCanariRepository {
  final SupabaseClient _client;
  RacesCanariRepository(this._client);

  Future<List<RaceCanari>> fetchAll() async {
    final rows = await _client.from('races_canari').select().order('categorie').order('nom');
    return (rows as List).map((r) => RaceCanari.fromJson(r as Map<String, dynamic>)).toList();
  }
}
