class StatutPonte {
  static const enCours = 'en_cours';
  static const eclos = 'eclos';
  static const echec = 'echec';

  static const all = [enCours, eclos, echec];
}

class Ponte {
  final String id;
  final String eleveurId;
  final String coupleId;
  final DateTime datePonte;
  final int nombreOeufs;
  final DateTime? dateEclosionPrevue;
  final int oeufsFecondes;
  final int oeufsClairs;
  final int oeufsCasses;
  final String statut;
  final String? notes;
  final DateTime createdAt;

  const Ponte({
    required this.id,
    required this.eleveurId,
    required this.coupleId,
    required this.datePonte,
    required this.nombreOeufs,
    this.dateEclosionPrevue,
    required this.oeufsFecondes,
    required this.oeufsClairs,
    required this.oeufsCasses,
    required this.statut,
    this.notes,
    required this.createdAt,
  });

  factory Ponte.fromJson(Map<String, dynamic> json) => Ponte(
        id: json['id'] as String,
        eleveurId: json['eleveur_id'] as String,
        coupleId: json['couple_id'] as String,
        datePonte: DateTime.parse(json['date_ponte'] as String),
        nombreOeufs: (json['nombre_oeufs'] as num).toInt(),
        dateEclosionPrevue: json['date_eclosion_prevue'] != null
            ? DateTime.parse(json['date_eclosion_prevue'] as String)
            : null,
        oeufsFecondes: (json['oeufs_fecondes'] as num).toInt(),
        oeufsClairs: (json['oeufs_clairs'] as num).toInt(),
        oeufsCasses: (json['oeufs_casses'] as num).toInt(),
        statut: json['statut'] as String,
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toInsertJson({required String eleveurId}) => {
        'eleveur_id': eleveurId,
        'couple_id': coupleId,
        'date_ponte': datePonte.toIso8601String().split('T').first,
        'nombre_oeufs': nombreOeufs,
        'date_eclosion_prevue': dateEclosionPrevue?.toIso8601String().split('T').first,
        'oeufs_fecondes': oeufsFecondes,
        'oeufs_clairs': oeufsClairs,
        'oeufs_casses': oeufsCasses,
        'statut': statut,
        'notes': notes,
      };

  Ponte copyWith({
    DateTime? datePonte,
    int? nombreOeufs,
    DateTime? dateEclosionPrevue,
    int? oeufsFecondes,
    int? oeufsClairs,
    int? oeufsCasses,
    String? statut,
    String? notes,
  }) {
    return Ponte(
      id: id,
      eleveurId: eleveurId,
      coupleId: coupleId,
      datePonte: datePonte ?? this.datePonte,
      nombreOeufs: nombreOeufs ?? this.nombreOeufs,
      dateEclosionPrevue: dateEclosionPrevue ?? this.dateEclosionPrevue,
      oeufsFecondes: oeufsFecondes ?? this.oeufsFecondes,
      oeufsClairs: oeufsClairs ?? this.oeufsClairs,
      oeufsCasses: oeufsCasses ?? this.oeufsCasses,
      statut: statut ?? this.statut,
      notes: notes ?? this.notes,
      createdAt: createdAt,
    );
  }
}

class Eclosion {
  final String id;
  final String eleveurId;
  final String ponteId;
  final DateTime dateEclosion;
  final int nombrePoussins;
  final int mortalite;
  final String? notes;
  final DateTime createdAt;

  const Eclosion({
    required this.id,
    required this.eleveurId,
    required this.ponteId,
    required this.dateEclosion,
    required this.nombrePoussins,
    required this.mortalite,
    this.notes,
    required this.createdAt,
  });

  factory Eclosion.fromJson(Map<String, dynamic> json) => Eclosion(
        id: json['id'] as String,
        eleveurId: json['eleveur_id'] as String,
        ponteId: json['ponte_id'] as String,
        dateEclosion: DateTime.parse(json['date_eclosion'] as String),
        nombrePoussins: (json['nombre_poussins'] as num).toInt(),
        mortalite: (json['mortalite'] as num).toInt(),
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toInsertJson() => {
        'ponte_id': ponteId,
        'date_eclosion': dateEclosion.toIso8601String().split('T').first,
        'nombre_poussins': nombrePoussins,
        'mortalite': mortalite,
        'notes': notes,
      };
}
