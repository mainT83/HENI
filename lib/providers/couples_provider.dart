import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/couples_repository.dart';
import '../models/couple.dart';
import 'supabase_provider.dart';

final couplesRepositoryProvider = Provider<CouplesRepository>((ref) {
  return CouplesRepository(ref.watch(supabaseClientProvider));
});

class CouplesListNotifier extends StateNotifier<AsyncValue<List<Couple>>> {
  final CouplesRepository _repo;

  CouplesListNotifier(this._repo) : super(const AsyncValue.loading()) {
    refresh();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final data = await _repo.fetchAll();
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

final couplesListProvider =
    StateNotifierProvider<CouplesListNotifier, AsyncValue<List<Couple>>>((ref) {
  return CouplesListNotifier(ref.watch(couplesRepositoryProvider));
});

/// Fiche détaillée d'un couple donné (rechargée à la demande).
final coupleDetailProvider = FutureProvider.family<Couple, String>((ref, id) async {
  return ref.watch(couplesRepositoryProvider).fetchById(id);
});
