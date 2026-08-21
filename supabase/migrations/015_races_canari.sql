-- =============================================================================
-- RACES DE CANARI : liste de référence (chant / couleur / posture), utilisée
-- pour l'autocomplétion du champ "race" d'un oiseau quand son espèce est un
-- canari. Table de référence partagée (comme especes), pas de RLS par éleveur.
-- =============================================================================

create table public.races_canari (
  id uuid primary key default gen_random_uuid(),
  categorie text not null check (categorie in ('chant', 'couleur', 'posture')),
  nom text not null,
  created_at timestamptz not null default now(),

  constraint race_canari_unique unique (categorie, nom)
);

comment on table public.races_canari is 'Liste de référence des races/variétés de canari, par catégorie (chant, couleur, posture)';

alter table public.races_canari enable row level security;

create policy "races_canari visibles par tout utilisateur authentifié"
  on public.races_canari for select
  to authenticated
  using (true);

insert into public.races_canari (categorie, nom) values
  -- Canaris de chant
  ('chant', 'Canaris Harz'),
  ('chant', 'Canaris Malinois'),
  ('chant', 'Canaris Timbrados'),
  ('chant', 'Canaris Chant Español'),
  ('chant', 'Canaris Slavujar'),

  -- Canaris de couleur
  ('couleur', 'Lipochrome blanc'),
  ('couleur', 'Lipochrome jaune'),
  ('couleur', 'Lipochrome rouge'),
  ('couleur', 'Albino, Lutino & Rubino'),
  ('couleur', 'Noir classique'),
  ('couleur', 'Brun classique'),
  ('couleur', 'Agate classique'),
  ('couleur', 'Isabelle classique'),
  ('couleur', 'Pastel'),
  ('couleur', 'Noir ailes grises'),
  ('couleur', 'Opale'),
  ('couleur', 'Phaeo'),
  ('couleur', 'Satiné'),
  ('couleur', 'Topaze'),
  ('couleur', 'Eumo'),
  ('couleur', 'Onyx'),
  ('couleur', 'Cobalt'),
  ('couleur', 'Jaspe simple facteur'),
  ('couleur', 'Mogno'),

  -- Canaris de posture
  ('posture', 'Arlequim Português Poupa (huppé)'),
  ('posture', 'Arlequim Português Par (non huppé)'),
  ('posture', 'Huppé Allemand'),
  ('posture', 'Irish Fancy'),
  ('posture', 'Lizard Bleu'),
  ('posture', 'Lizard Doré'),
  ('posture', 'Lizard Argenté'),
  ('posture', 'London Fancy'),
  ('posture', 'Gloster Corona'),
  ('posture', 'Gloster Consort'),
  ('posture', 'Crested'),
  ('posture', 'Crestbred'),
  ('posture', 'Norwich'),
  ('posture', 'Border'),
  ('posture', 'Fife Fancy'),
  ('posture', 'Hoso Japonais'),
  ('posture', 'Raza Española'),
  ('posture', 'Scotch Fancy'),
  ('posture', 'Bernois'),
  ('posture', 'Bossu Belge'),
  ('posture', 'Llarguet Español'),
  ('posture', 'Lancashire Huppé (Coppy)'),
  ('posture', 'Lancashire Non Huppé (Plainhead)'),
  ('posture', 'Münchener'),
  ('posture', 'Rheinländer Huppé'),
  ('posture', 'Rheinländer Non Huppé'),
  ('posture', 'Salentino Huppé'),
  ('posture', 'Salentino Non Huppé'),
  ('posture', 'Yorkshire'),
  ('posture', 'Rasmi'),
  ('posture', 'Gibber Italicus'),
  ('posture', 'Giboso Español'),
  ('posture', 'Giraldillo Sevillano'),
  ('posture', 'Frisé du Sud'),
  ('posture', 'Frisé Suisse'),
  ('posture', 'Melado Tinerfeño'),
  ('posture', 'Benacus'),
  ('posture', 'Fiorino Huppé'),
  ('posture', 'A.G.I'),
  ('posture', 'Frisé du Nord'),
  ('posture', 'Frisé Parisien'),
  ('posture', 'Mehringer'),
  ('posture', 'Padovan Huppé'),
  ('posture', 'Padovan Non Huppé'),
  ('posture', 'Rogetto')
on conflict (categorie, nom) do nothing;
