# Éleveur Pro — MVP

Application de gestion d'élevage d'oiseaux (Flutter + Supabase).

## État actuel

**Fait et vérifié autant que possible sans Flutter/Postgres installés ici :**
- Schéma Supabase complet (`supabase/migrations/`) : profils, espèces, oiseaux,
  couples, pontes, éclosions, notifications, généalogie, coefficient de
  consanguinité, stockage des photos.
- Le calcul du coefficient de consanguinité a été vérifié indépendamment en
  Python contre des cas de pedigree connus (frère×soeur=0.25, demi-fratrie et
  oncle×nièce=0.125, cousins germains=0.0625, père×fille=0.25...).
- Squelette Flutter : authentification (email + hooks Google/Apple),
  navigation, i18n FR/AR/EN, thème.
- Module **Oiseaux** complet : liste avec recherche/filtres, fiche détaillée
  (avec généalogie directe et alerte de consanguinité), formulaire
  création/édition avec photo.
- Tableau de bord avec les statistiques clés.

**Pas encore fait** (à développer module par module dans les prochains
échanges, sur le même modèle) : Couples, Pontes, Éclosions, arbre
généalogique graphique interactif, Sevrage, Santé, Finance, IA,
Marketplace — ces 5 derniers ne faisaient pas partie de votre liste MVP.

**Important** : Flutter/Dart ne sont pas installés dans cet environnement, ce
code n'a donc pas pu être compilé ni exécuté ici. Il faudra lancer
`flutter pub get` puis `flutter run` de votre côté et me signaler les erreurs
éventuelles pour que je les corrige.

## Mise en route

### 1. Créer le projet Supabase

Sur [supabase.com](https://supabase.com), créez un projet, puis dans
**SQL Editor**, exécutez les fichiers de `supabase/migrations/` **dans
l'ordre numérique** (001 à 010). Si vous avez le CLI Supabase :

```bash
supabase link --project-ref VOTRE_REF_PROJET
supabase db push
```

### 2. Configurer l'authentification sociale (optionnel pour démarrer)

Dans **Authentication > Providers** :
- **Google** : créez un OAuth Client ID sur Google Cloud Console, renseignez-le
  ici, puis configurez `google-services.json` (Android) et l'URL scheme iOS.
- **Apple** : activez "Sign in with Apple" dans les capacités Xcode de votre
  cible iOS, puis renseignez le Service ID côté Supabase.

L'authentification par email fonctionne sans configuration supplémentaire.

### 3. Configurer l'app Flutter

Récupérez l'URL et la clé "anon" de votre projet (Project Settings > API),
puis lancez avec :

```bash
flutter pub get
flutter run \
  --dart-define=SUPABASE_URL=https://votre-projet.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=votre_cle_anon
```

(Ou modifiez directement les valeurs par défaut dans
`lib/core/config/supabase_config.dart` pour le développement local.)

## Structure

```
lib/
  core/           configuration, thème, routeur, i18n
  models/         classes de données (Oiseau, Espece...)
  data/           repositories (accès Supabase)
  providers/      état Riverpod
  features/       écrans, organisés par module
  widgets/        composants partagés
supabase/migrations/   schéma SQL complet, numéroté dans l'ordre d'exécution
```
