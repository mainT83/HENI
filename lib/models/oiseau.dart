class StatutOiseau {
  static const reproducteur = 'reproducteur';
  static const jeune = 'jeune';
  static const aVendre = 'a_vendre';
  static const vendu = 'vendu';
  static const decede = 'decede';

  static const all = [reproducteur, jeune, aVendre, vendu, decede];
}

class SexeOiseau {
  static const male = 'male';
  static const femelle = 'femelle';
  static const indetermine = 'indetermine';

  static const all = [male, femelle, indetermine];
}

class Oiseau {
  final String id;
  final String eleveurId;
  final String numeroBague;
  final String? numeroSouche;
  final String? nom;
  final String especeId;
  final String? race;
  final String? mutation;
  final String sexe;
  final DateTime? dateNaissance;
  final String? eleveurOrigine;
  final String? pereId;
  final String? mereId;
  final String statut;
  final String? photoUrl;
  final String? notes;
  final DateTime createdAt;

  const Oiseau({
    required this.id,
    required this.eleveurId,
    required this.numeroBague,
    this.numeroSouche,
    this.nom,
    required this.especeId,
    this.race,
    this.mutation,
    required this.sexe,
    this.dateNaissance,
    this.eleveurOrigine,
    this.pereId,
    this.mereId,
    required this.statut,
    this.photoUrl,
    this.notes,
    required this.createdAt,
  });

  String get nomAffiche => (nom != null && nom!.trim().isNotEmpty) ? nom! : numeroBague;

  /// Numéro de bague suivi de l'année de naissance (ex: "99 - 2026"),
  /// pratique pour distinguer deux oiseaux qui partagent le même numéro
  /// d'une année à l'autre. Affichage uniquement — la valeur stockée en
  /// base (numeroBague) ne change pas.
  String get bagueAvecAnnee =>
      dateNaissance != null ? '$numeroBague - ${dateNaissance!.year}' : numeroBague;

  factory Oiseau.fromJson(Map<String, dynamic> json) => Oiseau(
        id: json['id'] as String,
        eleveurId: json['eleveur_id'] as String,
        numeroBague: json['numero_bague'] as String,
        numeroSouche: json['numero_souche'] as String?,
        nom: json['nom'] as String?,
        especeId: json['espece_id'] as String,
        race: json['race'] as String?,
        mutation: json['mutation'] as String?,
        sexe: json['sexe'] as String? ?? SexeOiseau.indetermine,
        dateNaissance: json['date_naissance'] != null
            ? DateTime.parse(json['date_naissance'] as String)
            : null,
        eleveurOrigine: json['eleveur_origine'] as String?,
        pereId: json['pere_id'] as String?,
        mereId: json['mere_id'] as String?,
        statut: json['statut'] as String? ?? StatutOiseau.jeune,
        photoUrl: json['photo_url'] as String?,
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  /// Payload pour insert/update (sans les champs générés par la base)
  Map<String, dynamic> toInsertJson({required String eleveurId}) => {
        'eleveur_id': eleveurId,
        'numero_bague': numeroBague,
        'numero_souche': numeroSouche,
        'nom': nom,
        'espece_id': especeId,
        'race': race,
        'mutation': mutation,
        'sexe': sexe,
        'date_naissance': dateNaissance?.toIso8601String().split('T').first,
        'eleveur_origine': eleveurOrigine,
        'pere_id': pereId,
        'mere_id': mereId,
        'statut': statut,
        'photo_url': photoUrl,
        'notes': notes,
      };

  Oiseau copyWith({
    String? numeroSouche,
    String? nom,
    String? especeId,
    String? race,
    String? mutation,
    String? sexe,
    DateTime? dateNaissance,
    String? eleveurOrigine,
    String? pereId,
    String? mereId,
    String? statut,
    String? photoUrl,
    String? notes,
  }) {
    return Oiseau(
      id: id,
      eleveurId: eleveurId,
      numeroBague: numeroBague,
      numeroSouche: numeroSouche ?? this.numeroSouche,
      nom: nom ?? this.nom,
      especeId: especeId ?? this.especeId,
      race: race ?? this.race,
      mutation: mutation ?? this.mutation,
      sexe: sexe ?? this.sexe,
      dateNaissance: dateNaissance ?? this.dateNaissance,
      eleveurOrigine: eleveurOrigine ?? this.eleveurOrigine,
      pereId: pereId ?? this.pereId,
      mereId: mereId ?? this.mereId,
      statut: statut ?? this.statut,
      photoUrl: photoUrl ?? this.photoUrl,
      notes: notes ?? this.notes,
      createdAt: createdAt,
    );
  }
}
