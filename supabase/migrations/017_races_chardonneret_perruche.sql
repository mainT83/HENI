-- =============================================================================
-- MUTATIONS COULEUR DU CHARDONNERET, et POSTURE/COULEUR DE LA PERRUCHE
-- ONDULÉE — même principe que races_canari, pour l'autocomplétion du champ
-- "race" quand l'espèce choisie correspond.
-- =============================================================================

create table public.races_chardonneret (
  id uuid primary key default gen_random_uuid(),
  nom text not null unique,
  created_at timestamptz not null default now()
);

comment on table public.races_chardonneret is 'Mutations couleur reconnues du chardonneret';

alter table public.races_chardonneret enable row level security;

create policy "races_chardonneret visibles par tout utilisateur authentifié"
  on public.races_chardonneret for select
  to authenticated
  using (true);

insert into public.races_chardonneret (nom) values
  ('Classique'), ('Brune'), ('Agate'), ('Pastel'), ('Isabelle'), ('Satinée'),
  ('Albino'), ('Opale'), ('Jaune'), ('Tête blanche'), ('Gorge blanche'),
  ('Panaché'), ('Blanc'), ('Noir'), ('Damas')
on conflict (nom) do nothing;


create table public.races_perruche_ondulee (
  id uuid primary key default gen_random_uuid(),
  categorie text not null check (categorie in ('posture', 'couleur')),
  nom text not null,
  created_at timestamptz not null default now(),

  constraint race_perruche_ondulee_unique unique (categorie, nom)
);

comment on table public.races_perruche_ondulee is 'Variétés de perruche ondulée, par catégorie (posture, couleur)';

alter table public.races_perruche_ondulee enable row level security;

create policy "races_perruche_ondulee visibles par tout utilisateur authentifié"
  on public.races_perruche_ondulee for select
  to authenticated
  using (true);

insert into public.races_perruche_ondulee (categorie, nom) values
  ('posture', 'Normal'),
  ('posture', 'Opaline'),
  ('posture', 'Cinnamon et Opaline Cinnamon'),
  ('posture', 'Ardoisées-Anthracite'),
  ('posture', 'Lutino-Albino-Ailes jaunes-Ailes blanches'),
  ('posture', 'Perlées'),
  ('posture', 'Pie dominant-Pie récessif'),
  ('posture', 'Autres'),

  ('couleur', 'Normal'),
  ('couleur', 'Opaline'),
  ('couleur', 'Cinnamon et Opaline Cinnamon'),
  ('couleur', 'Ardoisées-Anthracite'),
  ('couleur', 'Lutino-Albino-Ailes jaunes-Ailes blanches'),
  ('couleur', 'Perlées'),
  ('couleur', 'Pie dominant-Pie récessif'),
  ('couleur', 'Autres')
on conflict (categorie, nom) do nothing;
