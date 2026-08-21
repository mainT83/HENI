import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/notification_item.dart';
import '../../providers/notifications_provider.dart';
import '../../providers/locale_provider.dart';
import '../../core/theme/app_theme.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  IconData _icone(String type) {
    switch (type) {
      case TypeNotification.alerteCritique:
        return Icons.warning_amber_rounded;
      case TypeNotification.eclosionPrevue:
        return Icons.egg;
      case TypeNotification.pontePrevue:
        return Icons.favorite;
      case TypeNotification.vaccination:
      case TypeNotification.traitement:
        return Icons.medical_services_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _couleur(String type) {
    return type == TypeNotification.alerteCritique ? AppTheme.danger : AppTheme.primary;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).valueOrNull;
    final notificationsAsync = ref.watch(notificationsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t?.t('unread_notifications') ?? 'Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: t?.t('mark_all_read') ?? 'Tout marquer comme lu',
            onPressed: () => ref.read(notificationsListProvider.notifier).marquerToutesLues(),
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('${t?.t('error_generic') ?? 'Erreur'}: $e')),
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(child: Text(t?.t('no_results') ?? 'Aucune notification'));
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(notificationsListProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final n = notifications[i];
                final couleur = _couleur(n.type);
                return Dismissible(
                  key: ValueKey(n.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(color: AppTheme.danger.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.delete_outline, color: AppTheme.danger),
                  ),
                  onDismissed: (_) => ref.read(notificationsListProvider.notifier).supprimer(n.id),
                  child: Card(
                    color: n.lu ? null : couleur.withOpacity(0.05),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(10),
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundColor: couleur.withOpacity(0.12),
                        child: Icon(_icone(n.type), color: couleur, size: 20),
                      ),
                      title: Text(n.titre,
                          style: TextStyle(fontWeight: n.lu ? FontWeight.w400 : FontWeight.w700)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (n.message != null) Text(n.message!, maxLines: 2, overflow: TextOverflow.ellipsis),
                          Text(DateFormat('dd/MM/yyyy HH:mm').format(n.datePrevue),
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                        ],
                      ),
                      trailing: n.lu ? null : Container(width: 10, height: 10, decoration: BoxDecoration(color: couleur, shape: BoxShape.circle)),
                      onTap: () {
                        if (!n.lu) ref.read(notificationsListProvider.notifier).marquerLue(n.id);
                      },
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
