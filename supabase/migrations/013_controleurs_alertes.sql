-- =============================================================================
-- CONTRÔLEURS : compte Supabase dédié par boîtier Breeding Control, lié à son
-- éleveur, pour lui permettre d'écrire ses propres alertes critiques
-- (panne chauffage/humidificateur, capteur mort...) sans avoir les identifiants
-- complets de l'éleveur stockés sur le matériel.
-- =============================================================================

create table public.controleurs (
  id uuid primary key references auth.users (id) on delete cascade,
  eleveur_id uuid not null references public.profiles (id) on delete cascade,
  nom text not null default 'Breeding Control',
  created_at timestamptz not null default now()
);

comment on table public.controleurs is 'Compte Supabase Auth dédié à un boîtier physique, lié à l''éleveur propriétaire';

create index idx_controleurs_eleveur on public.controleurs (eleveur_id);

alter table public.controleurs enable row level security;

-- L'éleveur gère la liste de ses propres boîtiers.
create policy "controleurs gérés par leur éleveur"
  on public.controleurs for all
  using (auth.uid() = eleveur_id)
  with check (auth.uid() = eleveur_id);

-- Le boîtier peut lire sa propre ligne (pour retrouver son eleveur_id au démarrage).
create policy "un contrôleur peut lire sa propre ligne"
  on public.controleurs for select
  using (auth.uid() = id);

-- Un contrôleur authentifié peut insérer une notification pour l'éleveur
-- auquel il est lié (en plus de la policy existante qui couvre déjà l'éleveur
-- lui-même sur sa propre table notifications).
create policy "notifications: insertion par le contrôleur lié"
  on public.notifications for insert
  with check (
    exists (
      select 1 from public.controleurs c
      where c.id = auth.uid() and c.eleveur_id = notifications.eleveur_id
    )
  );

-- Ajoute le type d'alerte matérielle à la liste autorisée.
alter table public.notifications drop constraint notifications_type_check;
alter table public.notifications add constraint notifications_type_check
  check (type in (
    'ponte_prevue', 'eclosion_prevue', 'sevrage_prevu',
    'vaccination', 'traitement', 'autre', 'alerte_critique'
  ));
