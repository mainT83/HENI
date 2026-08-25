import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'supabase_provider.dart';

/// true si l'éleveur connecté a payé pour le plan premium (voir
/// profiles.is_premium, migration 011/019).
final isPremiumProvider = FutureProvider<bool>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final userId = client.auth.currentUser?.id;
  if (userId == null) return false;
  final row = await client.from('profiles').select('is_premium').eq('id', userId).single();
  return row['is_premium'] as bool? ?? false;
});
