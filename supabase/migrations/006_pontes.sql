-- =============================================================================
-- PONTES
-- =============================================================================

create table public.pontes (
  id uuid primary key default gen_random_uuid(),
  couple_id uuid not null references public.couples (id) on delete cascade,
  eleveur_id uuid not null references public.profiles (id) on delete cascade,

  date_ponte date not null default current_date,
  nombre_oeufs int not null default 0 check (nombre_oeufs >= 0),
  date_eclosion_prevue date,

  oeufs_fecondes int not null default 0 check (oeufs_fecondes >= 0),
  oeufs_clairs int not null default 0 check (oeufs_clairs >= 0),
  oeufs_casses int not null default 0 check (oeufs_casses >= 0),

  statut text not null default 'en_cours' check (statut in ('en_cours', 'eclos', 'echec')),
  notes text,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint controle_coherent check (oeufs_fecondes + oeufs_clairs + oeufs_casses <= nombre_oeufs)
);

comment on table public.pontes is 'Ponte d''un couple : nombre d''œufs, contrôle de fécondation, date d''éclosion prévue';

create index idx_pontes_couple on public.pontes (couple_id);
create index idx_pontes_eleveur on public.pontes (eleveur_id, statut);

alter table public.pontes enable row level security;

create policy "pontes gérées uniquement par leur éleveur"
  on public.pontes for all
  using (auth.uid() = eleveur_id)
  with check (auth.uid() = eleveur_id);

create trigger trg_pontes_updated_at
  before update on public.pontes
  for each row execute function public.set_updated_at();

-- Renseigne eleveur_id automatiquement depuis le couple (évite l'incohérence)
create function public.renseigner_eleveur_ponte()
returns trigger
language plpgsql
as $$
begin
  select eleveur_id into new.eleveur_id from public.couples where id = new.couple_id;
  return new;
end;
$$;

create trigger trg_renseigner_eleveur_ponte
  before insert on public.pontes
  for each row execute function public.renseigner_eleveur_ponte();

-- Notification automatique le jour de l'éclosion prévue
create function public.notifier_eclosion_prevue()
returns trigger
language plpgsql
as $$
begin
  if new.date_eclosion_prevue is not null then
    insert into public.notifications (eleveur_id, type, titre, message, date_prevue, entite_type, entite_id)
    values (
      new.eleveur_id,
      'eclosion_prevue',
      'Éclosion prévue',
      'Une éclosion est prévue pour la ponte du ' || to_char(new.date_ponte, 'DD/MM/YYYY'),
      new.date_eclosion_prevue::timestamptz,
      'ponte',
      new.id
    );
  end if;
  return new;
end;
$$;

create trigger trg_notifier_eclosion_prevue
  after insert on public.pontes
  for each row execute function public.notifier_eclosion_prevue();
