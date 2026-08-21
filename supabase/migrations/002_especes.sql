-- =============================================================================
-- ESPÈCES (table de référence partagée, pas de RLS par éleveur)
-- =============================================================================

create table public.especes (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  nom_fr text not null,
  nom_ar text not null,
  nom_en text not null,
  categorie text not null check (categorie in ('canari', 'chardonneret', 'perruche', 'perroquet', 'colombide', 'exotique', 'autre')),
  created_at timestamptz not null default now()
);

comment on table public.especes is 'Liste de référence des espèces, commune à tous les éleveurs';

alter table public.especes enable row level security;

create policy "especes visibles par tout utilisateur authentifié"
  on public.especes for select
  to authenticated
  using (true);

insert into public.especes (code, nom_fr, nom_ar, nom_en, categorie) values
  ('canari_domestique', 'Canari domestique', 'كناري منزلي', 'Domestic Canary', 'canari'),
  ('chardonneret_elegant', 'Chardonneret élégant', 'الحسون', 'European Goldfinch', 'chardonneret'),
  ('perruche_ondulee', 'Perruche ondulée', 'الدرة المموجة', 'Budgerigar', 'perruche'),
  ('perruche_calopsitte', 'Calopsitte', 'الكوكتيل', 'Cockatiel', 'perruche'),
  ('perruche_agapornis', 'Inséparable (Agapornis)', 'الحب الطائر', 'Lovebird', 'perruche'),
  ('perroquet_gris_gabon', 'Perroquet gris du Gabon', 'الببغاء الرمادي', 'African Grey Parrot', 'perroquet'),
  ('perroquet_ara', 'Ara', 'الببغاء الآرا', 'Macaw', 'perroquet'),
  ('pigeon_voyageur', 'Pigeon voyageur', 'حمام الزاجل', 'Racing Pigeon', 'colombide'),
  ('colombe_diamant', 'Diamant mandarin', 'دياموند', 'Diamond Dove', 'colombide'),
  ('exotique_autre', 'Autre oiseau exotique', 'طائر غريب آخر', 'Other Exotic Bird', 'exotique')
on conflict (code) do nothing;
