class Couple {
  final String id;
  final String eleveurId;
  final String maleId;
  final String femelleId;
  final DateTime dateFormation;
  final bool actif;
  final String? notes;
  final DateTime createdAt;

  const Couple({
    required this.id,
    required this.eleveurId,
    required this.maleId,
    required this.femelleId,
    required this.dateFormation,
    required this.actif,
    this.notes,
    required this.createdAt,
  });

  factory Couple.fromJson(Map<String, dynamic> json) => Couple(
        id: json['id'] as String,
        eleveurId: json['eleveur_id'] as String,
        maleId: json['male_id'] as String,
        femelleId: json['femelle_id'] as String,
        dateFormation: DateTime.parse(json['date_formation'] as String),
        actif: json['actif'] as bool,
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  /// Payload pour insert/update (sans les champs générés par la base)
  Map<String, dynamic> toInsertJson({required String eleveurId}) => {
        'eleveur_id': eleveurId,
        'male_id': maleId,
        'femelle_id': femelleId,
        'date_formation': dateFormation.toIso8601String().split('T').first,
        'actif': actif,
        'notes': notes,
      };

  Couple copyWith({
    String? maleId,
    String? femelleId,
    DateTime? dateFormation,
    bool? actif,
    String? notes,
  }) {
    return Couple(
      id: id,
      eleveurId: eleveurId,
      maleId: maleId ?? this.maleId,
      femelleId: femelleId ?? this.femelleId,
      dateFormation: dateFormation ?? this.dateFormation,
      actif: actif ?? this.actif,
      notes: notes ?? this.notes,
      createdAt: createdAt,
    );
  }
}
