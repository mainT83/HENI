class TypeTraitement {
  static const vaccin = 'vaccin';
  static const vermifuge = 'vermifuge';
  static const antiparasitaire = 'antiparasitaire';
  static const antibiotique = 'antibiotique';
  static const vitamine = 'vitamine';
  static const autre = 'autre';

  static const all = [vaccin, vermifuge, antiparasitaire, antibiotique, vitamine, autre];
}

class Traitement {
  final String id;
  final String eleveurId;
  final String oiseauId;
  final String type;
  final String nom;
  final String? description;
  final DateTime dateAdministration;
  final DateTime? dateRappel;
  final String? notes;
  final DateTime createdAt;

  const Traitement({
    required this.id,
    required this.eleveurId,
    required this.oiseauId,
    required this.type,
    required this.nom,
    this.description,
    required this.dateAdministration,
    this.dateRappel,
    this.notes,
    required this.createdAt,
  });

  factory Traitement.fromJson(Map<String, dynamic> json) => Traitement(
        id: json['id'] as String,
        eleveurId: json['eleveur_id'] as String,
        oiseauId: json['oiseau_id'] as String,
        type: json['type'] as String,
        nom: json['nom'] as String,
        description: json['description'] as String?,
        dateAdministration: DateTime.parse(json['date_administration'] as String),
        dateRappel: json['date_rappel'] != null ? DateTime.parse(json['date_rappel'] as String) : null,
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toInsertJson({required String oiseauId}) => {
        'oiseau_id': oiseauId,
        'type': type,
        'nom': nom,
        'description': description,
        'date_administration': dateAdministration.toIso8601String().split('T').first,
        'date_rappel': dateRappel?.toIso8601String().split('T').first,
        'notes': notes,
      };

  Traitement copyWith({
    String? type,
    String? nom,
    String? description,
    DateTime? dateAdministration,
    DateTime? dateRappel,
    bool clearDateRappel = false,
    String? notes,
  }) {
    return Traitement(
      id: id,
      eleveurId: eleveurId,
      oiseauId: oiseauId,
      type: type ?? this.type,
      nom: nom ?? this.nom,
      description: description ?? this.description,
      dateAdministration: dateAdministration ?? this.dateAdministration,
      dateRappel: clearDateRappel ? null : (dateRappel ?? this.dateRappel),
      notes: notes ?? this.notes,
      createdAt: createdAt,
    );
  }
}
