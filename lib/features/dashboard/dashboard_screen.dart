import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../providers/dashboard_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/theme_mode_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/feather_icon.dart';

const _moisAbrege = ['', 'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'];

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final t = ref.watch(translationsProvider).valueOrNull;
    final themeMode = ref.watch(themeModeProvider);
    final estSombre = themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(t?.t('dashboard') ?? 'Tableau de bord'),
        actions: [
          IconButton(
            icon: Icon(estSombre ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            tooltip: estSombre ? 'Mode clair' : 'Mode sombre',
            onPressed: () => ref.read(themeModeProvider.notifier).state =
                estSombre ? ThemeMode.light : ThemeMode.dark,
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: t?.t('unread_notifications') ?? 'Notifications',
            onPressed: () => context.push('/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: t?.t('settings') ?? 'Réglages',
            onPressed: () => context.push('/reglages'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardStatsProvider);
          ref.invalidate(tendanceMensuelleProvider);
          ref.invalidate(incubationsActivesProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _QuickActionsBanner(t: t),
            const SizedBox(height: 16),
            statsAsync.when(
              loading: () => const Center(child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              )),
              error: (e, st) => Text('${t?.t('error_generic') ?? 'Erreur'}: $e'),
              data: (stats) => GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.3,
                children: [
                  _StatCard(
                    label: t?.t('total_birds') ?? 'Oiseaux',
                    value: '${stats.totalOiseaux}',
                    iconWidget: const FeatherIcon(size: 28, color: AppTheme.amber),
                    color: AppTheme.amber,
                  ),
                  _StatCard(
                    label: t?.t('active_couples') ?? 'Couples actifs',
                    value: '${stats.couplesActifs}',
                    icon: Icons.favorite,
                    color: AppTheme.orange,
                  ),
                  _StatCard(
                    label: t?.t('young_birds') ?? 'Jeunes',
                    value: '${stats.jeunesEnElevage}',
                    icon: Icons.egg,
                    color: AppTheme.emerald,
                  ),
                  _StatCard(
                    label: t?.t('ongoing_clutches') ?? 'Pontes en cours',
                    value: '${stats.pontesEnCours}',
                    icon: Icons.hourglass_bottom,
                    color: AppTheme.purple,
                    onTap: () => context.push('/pontes'),
                  ),
                  _StatCard(
                    label: t?.t('hatch_rate') ?? "Taux d'éclosion",
                    value: stats.tauxEclosionGlobal != null
                        ? '${stats.tauxEclosionGlobal!.toStringAsFixed(0)}%'
                        : '--',
                    icon: Icons.show_chart,
                    color: AppTheme.primary,
                  ),
                  _StatCard(
                    label: t?.t('unread_notifications') ?? 'Notifications',
                    value: '${stats.notificationsNonLues}',
                    icon: Icons.notifications,
                    color: AppTheme.danger,
                    onTap: () => context.push('/notifications'),
                  ),
                  _StatCard(
                    label: t?.t('upcoming_treatments') ?? 'Traitements à venir',
                    value: '${stats.traitementsAVenir}',
                    icon: Icons.vaccines,
                    color: AppTheme.success,
                    onTap: () => context.push('/traitements'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _TendanceChart(t: t),
            const SizedBox(height: 20),
            _IncubationsActives(t: t),
          ],
        ),
      ),
    );
  }
}

class _QuickActionsBanner extends StatelessWidget {
  final dynamic t;
  const _QuickActionsBanner({required this.t});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withOpacity(0.15)),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          FilledButton.icon(
            onPressed: () => context.push('/oiseaux/nouveau'),
            icon: const Icon(Icons.add, size: 18),
            label: Text(t?.t('add_bird') ?? 'Ajouter un oiseau'),
          ),
          OutlinedButton.icon(
            onPressed: () => context.push('/couples/nouveau'),
            icon: const Icon(Icons.add, size: 18),
            label: Text(t?.t('add_couple') ?? 'Ajouter un couple'),
          ),
          OutlinedButton.icon(
            onPressed: () => context.push('/pontes/nouvelle'),
            icon: const Icon(Icons.add, size: 18),
            label: Text(t?.t('add_clutch') ?? 'Ajouter une ponte'),
          ),
          OutlinedButton.icon(
            onPressed: () => context.push('/traitements/nouveau'),
            icon: const Icon(Icons.add, size: 18),
            label: Text(t?.t('add_treatment') ?? 'Ajouter un traitement'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Widget? iconWidget;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.label,
    required this.value,
    this.icon,
    this.iconWidget,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              iconWidget ?? Icon(icon, color: color, size: 28),
              Text(value, style: Theme.of(context).textTheme.headlineSmall),
              Text(label,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TendanceChart extends ConsumerWidget {
  final dynamic t;
  const _TendanceChart({required this.t});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tendanceAsync = ref.watch(tendanceMensuelleProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Œufs pondus vs poussins éclos',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Row(
              children: [
                _Legende(color: AppTheme.warning, label: 'Œufs pondus'),
                const SizedBox(width: 16),
                _Legende(color: AppTheme.success, label: 'Poussins éclos'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: tendanceAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text('${t?.t('error_generic') ?? 'Erreur'}: $e')),
                data: (points) {
                  if (points.every((p) => p.oeufsPondus == 0 && p.poussinsEclos == 0)) {
                    return Center(child: Text(t?.t('no_results') ?? 'Aucune donnée pour l\'instant'));
                  }
                  final maxY = points
                      .map((p) => p.oeufsPondus > p.poussinsEclos ? p.oeufsPondus : p.poussinsEclos)
                      .fold<int>(1, (a, b) => a > b ? a : b)
                      .toDouble();
                  return LineChart(
                    LineChartData(
                      minY: 0,
                      maxY: maxY * 1.2,
                      gridData: const FlGridData(drawVerticalLine: false),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: true, reservedSize: 30, interval: maxY / 4 < 1 ? 1 : (maxY / 4).ceilToDouble()),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final i = value.toInt();
                              if (i < 0 || i >= points.length) return const SizedBox();
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(_moisAbrege[points[i].mois.month], style: const TextStyle(fontSize: 11)),
                              );
                            },
                          ),
                        ),
                      ),
                      lineBarsData: [
                        _ligne(points, (p) => p.oeufsPondus.toDouble(), AppTheme.warning),
                        _ligne(points, (p) => p.poussinsEclos.toDouble(), AppTheme.success),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  LineChartBarData _ligne(List<TendanceMensuelle> points, double Function(TendanceMensuelle) valeur, Color color) {
    return LineChartBarData(
      spots: [for (var i = 0; i < points.length; i++) FlSpot(i.toDouble(), valeur(points[i]))],
      isCurved: true,
      color: color,
      barWidth: 3,
      dotData: const FlDotData(show: true),
      belowBarData: BarAreaData(show: true, color: color.withOpacity(0.1)),
    );
  }
}

class _Legende extends StatelessWidget {
  final Color color;
  final String label;
  const _Legende({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _IncubationsActives extends ConsumerWidget {
  final dynamic t;
  const _IncubationsActives({required this.t});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incubationsAsync = ref.watch(incubationsActivesProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.hourglass_bottom, size: 18, color: AppTheme.warning),
                const SizedBox(width: 8),
                Text('Incubations en cours', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            incubationsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Text('${t?.t('error_generic') ?? 'Erreur'}: $e'),
              data: (incubations) {
                if (incubations.isEmpty) {
                  return Text(t?.t('no_results') ?? 'Aucune incubation en cours',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant));
                }
                return Column(
                  children: [
                    for (final inc in incubations) _IncubationTile(incubation: inc),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _IncubationTile extends StatelessWidget {
  final IncubationActive incubation;
  const _IncubationTile({required this.incubation});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('♂ ${incubation.maleNom} × ♀ ${incubation.femelleNom}',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 4),
                Text(
                  '🥚 ${incubation.nombreOeufs} œufs · 🔦 ${incubation.oeufsFecondes} fécondés',
                  style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.danger.withOpacity(0.1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Éclosion : ${DateFormat('dd/MM').format(incubation.dateEclosionPrevue)}',
              style: const TextStyle(fontSize: 10, color: AppTheme.danger, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
