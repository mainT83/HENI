import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/controller_repository.dart';

final controllerRepositoryProvider = Provider<ControllerRepository>((ref) {
  return ControllerRepository();
});

/// IP du contrôleur Breeding Control saisie par l'éleveur (affichée en
/// permanence sur l'écran LCD du boîtier, cf. system_manager.py).
final controllerIpProvider = StateProvider<String>((ref) => '');

class ControllerConnectionNotifier extends StateNotifier<AsyncValue<ControllerStatus>?> {
  final ControllerRepository _repo;
  final Ref _ref;

  ControllerConnectionNotifier(this._repo, this._ref) : super(null);

  Future<void> connecter() async {
    final ip = _ref.read(controllerIpProvider).trim();
    if (ip.isEmpty) return;

    state = const AsyncValue.loading();
    try {
      final status = await _repo.fetchStatus(ip);
      state = AsyncValue.data(status);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void deconnecter() {
    state = null;
  }
}

final controllerConnectionProvider =
    StateNotifierProvider<ControllerConnectionNotifier, AsyncValue<ControllerStatus>?>((ref) {
  return ControllerConnectionNotifier(ref.watch(controllerRepositoryProvider), ref);
});
