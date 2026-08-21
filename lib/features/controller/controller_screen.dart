import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/controller_provider.dart';
import '../../data/controller_repository.dart';
import '../../core/theme/app_theme.dart';

class ControllerScreen extends ConsumerStatefulWidget {
  const ControllerScreen({super.key});

  @override
  ConsumerState<ControllerScreen> createState() => _ControllerScreenState();
}

class _ControllerScreenState extends ConsumerState<ControllerScreen> {
  late final TextEditingController _ipCtrl;

  @override
  void initState() {
    super.initState();
    _ipCtrl = TextEditingController(text: ref.read(controllerIpProvider));
  }

  @override
  void dispose() {
    _ipCtrl.dispose();
    super.dispose();
  }

  void _connecter() {
    ref.read(controllerIpProvider.notifier).state = _ipCtrl.text.trim();
    ref.read(controllerConnectionProvider.notifier).connecter();
  }

  @override
  Widget build(BuildContext context) {
    final connexion = ref.watch(controllerConnectionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Contrôleur Breeding Control')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Adresse IP du contrôleur',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    "Affichée en permanence sur l'écran LCD du boîtier (ligne défilante).",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _ipCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: 'ex: 192.168.1.42',
                            isDense: true,
                          ),
                          onSubmitted: (_) => _connecter(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilledButton(
                        onPressed: _connecter,
                        child: const Text('Connecter'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (connexion == null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text('Renseignez l\'IP puis connectez-vous.',
                    style: TextStyle(color: Colors.grey.shade600)),
              ),
            )
          else
            connexion.when(
              loading: () => const Center(child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              )),
              error: (e, st) => Card(
                color: AppTheme.danger.withOpacity(0.08),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.wifi_off, color: AppTheme.danger),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          e is ControllerUnreachableException ? e.message : e.toString(),
                          style: const TextStyle(color: AppTheme.danger, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              data: (status) => _EtatContoleur(status: status),
            ),
        ],
      ),
    );
  }
}

class _EtatContoleur extends StatelessWidget {
  final ControllerStatus status;
  const _EtatContoleur({required this.status});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Chip(
              avatar: Icon(status.wifiMode == 'ap' ? Icons.wifi_tethering : Icons.wifi,
                  size: 16, color: Colors.white),
              label: Text('${status.wifiMode == 'ap' ? 'Point d\'accès' : 'WiFi'} · ${status.wifiIp}'),
              backgroundColor: status.wifiMode == 'ap' ? AppTheme.warning : AppTheme.success,
              labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            const SizedBox(width: 8),
            Chip(
              label: Text(_libelleMode(status.mode)),
              backgroundColor: AppTheme.primary.withOpacity(0.12),
              labelStyle: const TextStyle(color: AppTheme.primary, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _MesureCard(
                icon: Icons.thermostat,
                label: 'Température',
                value: status.temp != null ? '${status.temp!.toStringAsFixed(1)}°C' : '--',
                color: status.relaisTemp ? AppTheme.danger : AppTheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MesureCard(
                icon: Icons.water_drop,
                label: 'Humidité',
                value: status.hum != null ? '${status.hum!.toStringAsFixed(1)}%' : '--',
                color: status.relaisHum ? AppTheme.danger : AppTheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Sorties lumineuses', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                for (var i = 0; i < status.dutiesPct.length; i++) ...[
                  _SortieBar(label: 'S${i + 1}', pourcentage: status.dutiesPct[i]),
                  if (i < status.dutiesPct.length - 1) const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ),
        if (status.saison != null) ...[
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.calendar_month, color: AppTheme.primary),
              title: Text(status.saison!),
              subtitle: Text('${status.date} · ${status.heure}'),
            ),
          ),
        ],
      ],
    );
  }

  String _libelleMode(String mode) {
    switch (mode) {
      case 'manuel':
        return 'Manuel';
      case 'cycles':
        return 'Cycles saisonniers';
      case 'menu':
        return 'Menu';
      default:
        return 'Automatique';
    }
  }
}

class _MesureCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MesureCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _SortieBar extends StatelessWidget {
  final String label;
  final int pourcentage;

  const _SortieBar({required this.label, required this.pourcentage});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 28, child: Text(label, style: const TextStyle(fontSize: 12))),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pourcentage / 100,
              minHeight: 10,
              backgroundColor: Colors.grey.shade200,
              color: AppTheme.warning,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(width: 36, child: Text('$pourcentage%', style: const TextStyle(fontSize: 12))),
      ],
    );
  }
}
