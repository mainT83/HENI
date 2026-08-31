import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_provider.dart';

class TendanceMensuelle {
  final DateTime mois;
  final int oeufsPondus;
  final int poussinsEclos;

  TendanceMensuelle.fromJson(Map<String, dynamic> json)
      : mois = DateTime.parse(json['mois'] as String),
        oeufsPondus = (json['oeufs_pondus'] as num).toInt(),
        poussinsEclos = (json['poussins_eclos'] as num).toInt();
}

final tendanceMensuelleProvider = FutureProvider<List<TendanceMensuelle>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final rows = await client.rpc('tendance_mensuelle', params: {'p_nb_mois': 6});
  return (rows as List)
      .map((r) => TendanceMensuelle.fromJson(r as Map<String, dynamic>))
      .toList();
});

/// Ponte en cours d'incubation, avec le nom des parents pour l'affichage.
class IncubationActive {
  final String id;
  final String coupleId;
  final DateTime dateEclosionPrevue;
  final int nombreOeufs;
  final int oeufsFecondes;
  final String maleNom;
  final String femelleNom;

  const IncubationActive({
    required this.id,
    required this.coupleId,
    required this.dateEclosionPrevue,
    required this.nombreOeufs,
    required this.oeufsFecondes,
    required this.maleNom,
    required this.femelleNom,
  });
}

final incubationsActivesProvider = FutureProvider<List<IncubationActive>>((ref) async {
  final client = ref.watch(supabaseClientProvider);

  final pontes = await client
      .from('pontes')
      .select('id, couple_id, date_eclosion_prevue, nombre_oeufs, oeufs_fecondes')
      .eq('statut', 'en_cours')
      .not('date_eclosion_prevue', 'is', null)
      .order('date_eclosion_prevue')
      .limit(5) as List;

  if (pontes.isEmpty) return [];

  final coupleIds = pontes.map((p) => p['couple_id'] as String).toSet().toList();
  final couples = await client.from('couples').select('id, male_id, femelle_id').inFilter('id', coupleIds) as List;
  final couplesById = {for (final c in couples) c['id'] as String: c};

  final oiseauIds = couples.expand((c) => [c['male_id'] as String, c['femelle_id'] as String]).toSet().toList();
  final oiseaux = oiseauIds.isEmpty
      ? []
      : await client.from('oiseaux').select('id, nom, numero_bague').inFilter('id', oiseauIds) as List;
  final oiseauxById = {for (final o in oiseaux) o['id'] as String: o};

  String nomOiseau(String? id) {
    if (id == null) return '?';
    final o = oiseauxById[id];
    if (o == null) return '?';
    final nom = o['nom'] as String?;
    return (nom != null && nom.trim().isNotEmpty) ? nom : (o['numero_bague'] as String);
  }

  return pontes.map((p) {
    final couple = couplesById[p['couple_id'] as String];
    return IncubationActive(
      id: p['id'] as String,
      coupleId: p['couple_id'] as String,
      dateEclosionPrevue: DateTime.parse(p['date_eclosion_prevue'] as String),
      nombreOeufs: (p['nombre_oeufs'] as num).toInt(),
      oeufsFecondes: (p['oeufs_fecondes'] as num).toInt(),
      maleNom: nomOiseau(couple?['male_id'] as String?),
      femelleNom: nomOiseau(couple?['femelle_id'] as String?),
    );
  }).toList();
});

class DashboardStats {
  final int totalOiseaux;
  final int couplesActifs;
  final int jeunesEnElevage;
  final int pontesEnCours;
  final double? tauxEclosionGlobal;
  final int notificationsNonLues;
  final int traitementsAVenir;

  DashboardStats.fromJson(Map<String, dynamic> json)
      : totalOiseaux = (json['total_oiseaux'] as num).toInt(),
        couplesActifs = (json['couples_actifs'] as num).toInt(),
        jeunesEnElevage = (json['jeunes_en_elevage'] as num).toInt(),
        pontesEnCours = (json['pontes_en_cours'] as num).toInt(),
        tauxEclosionGlobal = (json['taux_eclosion_global'] as num?)?.toDouble(),
        notificationsNonLues = (json['notifications_non_lues'] as num).toInt(),
        traitementsAVenir = (json['traitements_a_venir'] as num).toInt();
}

final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final rows = await _rpcAvecReessai(client, 'dashboard_stats');
  final row = (rows as List).first as Map<String, dynamic>;
  return DashboardStats.fromJson(row);
});

/// Juste après une connexion (surtout OAuth), le jeton fraîchement émis peut
/// être rejeté par un décalage d'horloge côté serveur (PostgrestException
/// "JWT issued at future", code PGRST303). Un simple délai ne suffit pas
/// toujours : on force explicitement l'émission d'un jeton neuf via
/// refreshSession() avant de réessayer, jusqu'à 3 fois.
Future<dynamic> _rpcAvecReessai(SupabaseClient client, String fonction) async {
  for (var tentative = 0; ; tentative++) {
    try {
      return await client.rpc(fonction);
    } on PostgrestException catch (e) {
      if (e.code != 'PGRST303' || tentative >= 2) rethrow;
      await Future.delayed(Duration(seconds: 2 * (tentative + 1)));
      try {
        await client.auth.refreshSession();
      } catch (_) {
        // Si le rafraîchissement échoue, on retente quand même l'appel tel quel.
      }
    }
  }
}
