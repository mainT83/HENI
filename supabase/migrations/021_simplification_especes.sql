-- =============================================================================
-- Simplifie la liste d'espèces affichée dans le formulaire "Ajouter un
-- oiseau" à 6 choix génériques : Canaris de chant, Canaris de couleur,
-- Canaris de posture, Psittacidés, Chardonneret, Autre.
--
-- Les anciennes espèces détaillées (canari domestique, perruches,
-- perroquets, estrildidés...) restent en base avec actif = false : elles ne
-- s'affichent plus dans le sélecteur mais restent valides pour les oiseaux
-- déjà enregistrés dessus (contrainte de clé étrangère oiseaux.espece_id).
-- =============================================================================

alter table public.especes add column if not exists actif boolean not null default true;

alter table public.especes drop constraint especes_categorie_check;
alter table public.especes add constraint especes_categorie_check
  check (categorie in ('canari', 'canari_chant', 'canari_couleur', 'canari_posture', 'chardonneret',
                        'perruche', 'perroquet', 'psittacide', 'colombide', 'estrildide', 'exotique', 'autre'));

update public.especes set actif = false;

-- Réutilise 'chardonneret_elegant' et 'exotique_autre' comme entrées
-- "Chardonneret" et "Autre" de la nouvelle liste, pour éviter les doublons.
update public.especes set nom_fr = 'Chardonneret', actif = true where code = 'chardonneret_elegant';
update public.especes set nom_fr = 'Autre', nom_en = 'Other', actif = true where code = 'exotique_autre';

insert into public.especes (code, nom_fr, nom_ar, nom_en, categorie, duree_incubation_jours, actif) values
  ('canari_chant', 'Canaris de chant', 'كناري الغناء', 'Song Canary', 'canari_chant', 13, true),
  ('canari_couleur', 'Canaris de couleur', 'كناري الألوان', 'Color Canary', 'canari_couleur', 13, true),
  ('canari_posture', 'Canaris de posture', 'كناري الوضعية', 'Posture Canary', 'canari_posture', 13, true),
  ('psittacides', 'Psittacidés', 'الببغائيات', 'Psittacines', 'psittacide', null, true)
on conflict (code) do update set nom_fr = excluded.nom_fr, categorie = excluded.categorie, actif = true;
