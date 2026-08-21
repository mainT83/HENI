class Espece {
  final String id;
  final String code;
  final String nomFr;
  final String nomAr;
  final String nomEn;
  final String categorie;
  final int? dureeIncubationJours;

  const Espece({
    required this.id,
    required this.code,
    required this.nomFr,
    required this.nomAr,
    required this.nomEn,
    required this.categorie,
    this.dureeIncubationJours,
  });

  factory Espece.fromJson(Map<String, dynamic> json) => Espece(
        id: json['id'] as String,
        code: json['code'] as String,
        nomFr: json['nom_fr'] as String,
        nomAr: json['nom_ar'] as String,
        nomEn: json['nom_en'] as String,
        categorie: json['categorie'] as String,
        dureeIncubationJours: (json['duree_incubation_jours'] as num?)?.toInt(),
      );

  String nomPourLangue(String langue) {
    switch (langue) {
      case 'ar':
        return nomAr;
      case 'en':
        return nomEn;
      default:
        return nomFr;
    }
  }
}
