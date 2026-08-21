class TypeNotification {
  static const pontePrevue = 'ponte_prevue';
  static const eclosionPrevue = 'eclosion_prevue';
  static const sevragePrevu = 'sevrage_prevu';
  static const vaccination = 'vaccination';
  static const traitement = 'traitement';
  static const alerteCritique = 'alerte_critique';
  static const autre = 'autre';
}

class NotificationItem {
  final String id;
  final String eleveurId;
  final String type;
  final String titre;
  final String? message;
  final DateTime datePrevue;
  final String? entiteType;
  final String? entiteId;
  final bool lu;
  final DateTime createdAt;

  const NotificationItem({
    required this.id,
    required this.eleveurId,
    required this.type,
    required this.titre,
    this.message,
    required this.datePrevue,
    this.entiteType,
    this.entiteId,
    required this.lu,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) => NotificationItem(
        id: json['id'] as String,
        eleveurId: json['eleveur_id'] as String,
        type: json['type'] as String,
        titre: json['titre'] as String,
        message: json['message'] as String?,
        datePrevue: DateTime.parse(json['date_prevue'] as String),
        entiteType: json['entite_type'] as String?,
        entiteId: json['entite_id'] as String?,
        lu: json['lu'] as bool,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
