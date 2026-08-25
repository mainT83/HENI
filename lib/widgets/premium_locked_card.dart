import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Affiché à la place d'une fonctionnalité premium (suivi généalogique /
/// consanguinité) quand l'éleveur est sur le plan gratuit.
class PremiumLockedCard extends StatelessWidget {
  final String titre;
  final String message;

  const PremiumLockedCard({
    super.key,
    required this.titre,
    this.message = 'Disponible avec le plan premium.',
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.lock_outline, color: AppTheme.warning),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titre, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(message,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
