import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/pontes_repository.dart';
import '../models/ponte.dart';
import 'supabase_provider.dart';

final pontesRepositoryProvider = Provider<PontesRepository>((ref) {
  return PontesRepository(ref.watch(supabaseClientProvider));
});

class PontesListNotifier extends StateNotifier<AsyncValue<List<Ponte>>> {
  final PontesRepository _repo;

  PontesListNotifier(this._repo) : super(const AsyncValue.loading()) {
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
}

final pontesListProvider = StateNotifierProvider<PontesListNotifier, AsyncValue<List<Ponte>>>((ref) {
  return PontesListNotifier(ref.watch(pontesRepositoryProvider));
});

final ponteDetailProvider = FutureProvider.family<Ponte, String>((ref, id) async {
  return ref.watch(pontesRepositoryProvider).fetchById(id);
});

final eclosionsProvider = FutureProvider.family<List<Eclosion>, String>((ref, ponteId) async {
  return ref.watch(pontesRepositoryProvider).fetchEclosions(ponteId);
});
