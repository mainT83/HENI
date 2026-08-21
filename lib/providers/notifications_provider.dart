import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/notifications_repository.dart';
import '../models/notification_item.dart';
import 'supabase_provider.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return NotificationsRepository(ref.watch(supabaseClientProvider));
});

class NotificationsListNotifier extends StateNotifier<AsyncValue<List<NotificationItem>>> {
  final NotificationsRepository _repo;

  NotificationsListNotifier(this._repo) : super(const AsyncValue.loading()) {
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

  Future<void> marquerLue(String id) async {
    await _repo.marquerLue(id);
    await refresh();
  }

  Future<void> marquerToutesLues() async {
    await _repo.marquerToutesLues();
    await refresh();
  }

  Future<void> supprimer(String id) async {
    await _repo.supprimer(id);
    await refresh();
  }
}

final notificationsListProvider =
    StateNotifierProvider<NotificationsListNotifier, AsyncValue<List<NotificationItem>>>((ref) {
  return NotificationsListNotifier(ref.watch(notificationsRepositoryProvider));
});
