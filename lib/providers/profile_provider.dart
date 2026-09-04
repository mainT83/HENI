import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

/// Numéro de souche fixe de l'éleveur connecté — utilisé automatiquement
/// pour les oiseaux nés chez lui, distingue ses oiseaux de ceux achetés
/// ailleurs qui pourraient partager le même numéro de bague.
final numeroSoucheProvider = FutureProvider<String?>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final userId = client.auth.currentUser?.id;
  if (userId == null) return null;
  final row = await client.from('profiles').select('numero_souche').eq('id', userId).single();
  return row['numero_souche'] as String?;
});

Future<void> definirNumeroSouche(SupabaseClient client, String numeroSouche) async {
  final userId = client.auth.currentUser!.id;
  await client.from('profiles').update({'numero_souche': numeroSouche}).eq('id', userId);
}
