import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/traitements_repository.dart';
import '../models/traitement.dart';
import 'supabase_provider.dart';

final traitementsRepositoryProvider = Provider<TraitementsRepository>((ref) {
  return TraitementsRepository(ref.watch(supabaseClientProvider));
});

class TraitementsListNotifier extends StateNotifier<AsyncValue<List<Traitement>>> {
  final TraitementsRepository _repo;
  final String? _oiseauId;

  TraitementsListNotifier(this._repo, this._oiseauId) : super(const AsyncValue.loading()) {
    refresh();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final data = await _repo.fetchAll(oiseauId: _oiseauId);
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> supprimer(String id) async {
    await _repo.delete(id);
    await refresh();
  }
}

/// Liste des traitements — passez l'id d'un oiseau pour filtrer sur celui-ci,
/// ou null pour tous les traitements de l'éleveur.
final traitementsListProvider = StateNotifierProvider.family<TraitementsListNotifier,
    AsyncValue<List<Traitement>>, String?>((ref, oiseauId) {
  return TraitementsListNotifier(ref.watch(traitementsRepositoryProvider), oiseauId);
});

final traitementDetailProvider = FutureProvider.family<Traitement, String>((ref, id) async {
  return ref.watch(traitementsRepositoryProvider).fetchById(id);
});
