-- =============================================================================
-- NOTIFICATIONS
-- Créée avant pontes/eclosions car leurs triggers y insèrent des rappels.
-- =============================================================================

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  eleveur_id uuid not null references public.profiles (id) on delete cascade,

  type text not null check (type in (
    'ponte_prevue', 'eclosion_prevue', 'sevrage_prevu',
    'vaccination', 'traitement', 'autre'
  )),
  titre text not null,
  message text,
  date_prevue timestamptz not null,

  entite_type text,
  entite_id uuid,

  lu boolean not null default false,
  created_at timestamptz not null default now()
);

comment on table public.notifications is 'Rappels et notifications programmées pour l''éleveur';

create index idx_notifications_eleveur on public.notifications (eleveur_id, date_prevue);
create index idx_notifications_non_lues on public.notifications (eleveur_id) where lu = false;

alter table public.notifications enable row level security;

create policy "notifications gérées uniquement par leur éleveur"
  on public.notifications for all
  using (auth.uid() = eleveur_id)
  with check (auth.uid() = eleveur_id);
