import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/espece.dart';

class EspecesRepository {
  final SupabaseClient _client;
  EspecesRepository(this._client);

  Future<List<Espece>> fetchAll() async {
    final rows = await _client.from('especes').select().eq('actif', true).order('nom_fr');
    return (rows as List).map((r) => Espece.fromJson(r as Map<String, dynamic>)).toList();
  }
}
