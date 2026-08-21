import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_item.dart';

class NotificationsRepository {
  final SupabaseClient _client;
  NotificationsRepository(this._client);

  String get _eleveurId => _client.auth.currentUser!.id;

  Future<List<NotificationItem>> fetchAll() async {
    final rows = await _client
        .from('notifications')
        .select()
        .eq('eleveur_id', _eleveurId)
        .order('date_prevue', ascending: false);
    return (rows as List).map((r) => NotificationItem.fromJson(r as Map<String, dynamic>)).toList();
  }

  Future<void> marquerLue(String id) async {
    await _client.from('notifications').update({'lu': true}).eq('id', id);
  }

  Future<void> marquerToutesLues() async {
    await _client.from('notifications').update({'lu': true}).eq('eleveur_id', _eleveurId).eq('lu', false);
  }

  Future<void> supprimer(String id) async {
    await _client.from('notifications').delete().eq('id', id);
  }
}
