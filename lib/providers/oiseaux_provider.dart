import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/oiseaux_repository.dart';
import '../data/especes_repository.dart';
import '../data/races_canari_repository.dart';
import '../data/races_reference_repository.dart';
import '../models/oiseau.dart';
import '../models/espece.dart';
import '../models/race_canari.dart';
import 'supabase_provider.dart';

final oiseauxRepositoryProvider = Provider<OiseauxRepository>((ref) {
  return OiseauxRepository(ref.watch(supabaseClientProvider));
});

final especesRepositoryProvider = Provider<EspecesRepository>((ref) {
  return EspecesRepository(ref.watch(supabaseClientProvider));
});

/// Liste des espèces, chargée une fois (table de référence peu volatile).
final especesProvider = FutureProvider<List<Espece>>((ref) async {
  return ref.watch(especesRepositoryProvider).fetchAll();
});

final racesCanariRepositoryProvider = Provider<RacesCanariRepository>((ref) {
  return RacesCanariRepository(ref.watch(supabaseClientProvider));
});

/// Liste des races de canari (chant/couleur/posture), pour l'autocomplétion
/// du champ "race" quand l'espèce choisie est un canari.
final racesCanariProvider = FutureProvider<List<RaceCanari>>((ref) async {
  return ref.watch(racesCanariRepositoryProvider).fetchAll();
});

/// Mutations couleur du chardonneret, pour l'autocomplétion du champ "race".
final racesChardonneretProvider = FutureProvider<List<String>>((ref) async {
  return RacesSimpleRepository(ref.watch(supabaseClientProvider), 'races_chardonneret').fetchAll();
});

/// Variétés de perruche ondulée (posture/couleur), pour l'autocomplétion du
/// champ "race" — MapEntry(categorie, nom).
final racesPerrucheOnduleeProvider = FutureProvider<List<MapEntry<String, String>>>((ref) async {
  return RacesCategoriseesRepository(ref.watch(supabaseClientProvider), 'races_perruche_ondulee').fetchAll();
});

class OiseauxFilter {
  final String? statut;
  final String recherche;
  const OiseauxFilter({this.statut, this.recherche = ''});

  OiseauxFilter copyWith({String? statut, bool clearStatut = false, String? recherche}) {
    return OiseauxFilter(
      statut: clearStatut ? null : (statut ?? this.statut),
      recherche: recherche ?? this.recherche,
    );
  }
}

final oiseauxFilterProvider = StateProvider<OiseauxFilter>((ref) => const OiseauxFilter());

class OiseauxListNotifier extends StateNotifier<AsyncValue<List<Oiseau>>> {
  final OiseauxRepository _repo;
  final Ref _ref;

  OiseauxListNotifier(this._repo, this._ref) : super(const AsyncValue.loading()) {
    refresh();
    _ref.listen(oiseauxFilterProvider, (_, __) => refresh());
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    final filter = _ref.read(oiseauxFilterProvider);
    try {
      final data = await _repo.fetchAll(statut: filter.statut, recherche: filter.recherche);
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

final oiseauxListProvider =
    StateNotifierProvider<OiseauxListNotifier, AsyncValue<List<Oiseau>>>((ref) {
  return OiseauxListNotifier(ref.watch(oiseauxRepositoryProvider), ref);
});

/// Fiche détaillée d'un oiseau donné (rechargée à la demande).
final oiseauDetailProvider =
    FutureProvider.family<Oiseau, String>((ref, id) async {
  return ref.watch(oiseauxRepositoryProvider).fetchById(id);
});

final ancetresProvider =
    FutureProvider.family<List<OiseauAncetre>, String>((ref, oiseauId) async {
  return ref.watch(oiseauxRepositoryProvider).ancetres(oiseauId);
});

final descendantsProvider =
    FutureProvider.family<List<OiseauAncetre>, String>((ref, oiseauId) async {
  return ref.watch(oiseauxRepositoryProvider).descendants(oiseauId);
});

final consanguiniteProvider =
    FutureProvider.family<double, String>((ref, oiseauId) async {
  return ref.watch(oiseauxRepositoryProvider).consanguiniteOiseau(oiseauId);
});
