class CategorieRaceCanari {
  static const chant = 'chant';
  static const couleur = 'couleur';
  static const posture = 'posture';
}

class RaceCanari {
  final String id;
  final String categorie;
  final String nom;

  const RaceCanari({required this.id, required this.categorie, required this.nom});

  factory RaceCanari.fromJson(Map<String, dynamic> json) => RaceCanari(
        id: json['id'] as String,
        categorie: json['categorie'] as String,
        nom: json['nom'] as String,
      );

  String get categorieLabel {
    switch (categorie) {
      case CategorieRaceCanari.chant:
        return 'Chant';
      case CategorieRaceCanari.couleur:
        return 'Couleur';
      case CategorieRaceCanari.posture:
        return 'Posture';
      default:
        return categorie;
    }
  }
}
