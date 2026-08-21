-- =============================================================================
-- ÉCLOSIONS
-- =============================================================================

create table public.eclosions (
  id uuid primary key default gen_random_uuid(),
  ponte_id uuid not null references public.pontes (id) on delete cascade,
  eleveur_id uuid not null references public.profiles (id) on delete cascade,

  date_eclosion date not null default current_date,
  nombre_poussins int not null default 0 check (nombre_poussins >= 0),
  mortalite int not null default 0 check (mortalite >= 0),
  notes text,

  created_at timestamptz not null default now()
);

comment on table public.eclosions is 'Résultat d''éclosion d''une ponte (peut être enregistré en plusieurs fois si étalé sur quelques jours)';

create index idx_eclosions_ponte on public.eclosions (ponte_id);
create index idx_eclosions_eleveur on public.eclosions (eleveur_id);

alter table public.eclosions enable row level security;

create policy "eclosions gérées uniquement par leur éleveur"
  on public.eclosions for all
  using (auth.uid() = eleveur_id)
  with check (auth.uid() = eleveur_id);

create function public.renseigner_eleveur_eclosion()
returns trigger
language plpgsql
as $$
begin
  select eleveur_id into new.eleveur_id from public.pontes where id = new.ponte_id;
  return new;
end;
$$;

create trigger trg_renseigner_eleveur_eclosion
  before insert on public.eclosions
  for each row execute function public.renseigner_eleveur_eclosion();

-- Marque la ponte comme éclose dès qu'une éclosion est enregistrée
create function public.marquer_ponte_eclose()
returns trigger
language plpgsql
as $$
begin
  update public.pontes set statut = 'eclos' where id = new.ponte_id and statut = 'en_cours';
  return new;
end;
$$;

create trigger trg_marquer_ponte_eclose
  after insert on public.eclosions
  for each row execute function public.marquer_ponte_eclose();

-- =============================================================================
-- Enregistrement d'un jeune oiseau né d'une éclosion (appelée depuis Flutter
-- via supabase.rpc(), un poussin à la fois puisque le numéro de bague est
-- physique et attribué individuellement par l'éleveur).
-- =============================================================================

create function public.creer_jeune_depuis_eclosion(
  p_eclosion_id uuid,
  p_numero_bague text,
  p_sexe text default 'indetermine',
  p_nom text default null
)
returns public.oiseaux
language plpgsql
security invoker
as $$
declare
  v_couple record;
  v_eclosion record;
  v_espece_id uuid;
  v_nouvel_oiseau public.oiseaux;
begin
  select e.*, p.couple_id into v_eclosion
  from public.eclosions e
  join public.pontes p on p.id = e.ponte_id
  where e.id = p_eclosion_id;

  if v_eclosion is null then
    raise exception 'Éclosion introuvable: %', p_eclosion_id;
  end if;

  select c.male_id, c.femelle_id, c.eleveur_id into v_couple
  from public.couples c
  join public.pontes p on p.couple_id = c.id
  where p.id = v_eclosion.ponte_id;

  select espece_id into v_espece_id from public.oiseaux where id = v_couple.femelle_id;

  insert into public.oiseaux (
    eleveur_id, numero_bague, nom, espece_id, sexe,
    date_naissance, pere_id, mere_id, statut
  ) values (
    v_couple.eleveur_id, p_numero_bague, p_nom, v_espece_id, p_sexe,
    v_eclosion.date_eclosion, v_couple.male_id, v_couple.femelle_id, 'jeune'
  )
  returning * into v_nouvel_oiseau;

  return v_nouvel_oiseau;
end;
$$;
