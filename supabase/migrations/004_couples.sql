-- =============================================================================
-- COUPLES REPRODUCTEURS
-- =============================================================================

create table public.couples (
  id uuid primary key default gen_random_uuid(),
  eleveur_id uuid not null references public.profiles (id) on delete cascade,

  male_id uuid not null references public.oiseaux (id) on delete cascade,
  femelle_id uuid not null references public.oiseaux (id) on delete cascade,

  date_formation date not null default current_date,
  actif boolean not null default true,
  notes text,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint couple_unique unique (male_id, femelle_id)
);

comment on table public.couples is 'Couple reproducteur (un mâle + une femelle)';

create index idx_couples_eleveur on public.couples (eleveur_id);
create index idx_couples_male on public.couples (male_id);
create index idx_couples_femelle on public.couples (femelle_id);

alter table public.couples enable row level security;

create policy "couples gérés uniquement par leur éleveur"
  on public.couples for all
  using (auth.uid() = eleveur_id)
  with check (auth.uid() = eleveur_id);

create trigger trg_couples_updated_at
  before update on public.couples
  for each row execute function public.set_updated_at();

-- Vérifie la cohérence : sexe correct, même éleveur pour les 2 oiseaux et le couple
create function public.valider_couple()
returns trigger
language plpgsql
as $$
declare
  sexe_male text;
  eleveur_male uuid;
  sexe_femelle text;
  eleveur_femelle uuid;
begin
  select sexe, eleveur_id into sexe_male, eleveur_male from public.oiseaux where id = new.male_id;
  select sexe, eleveur_id into sexe_femelle, eleveur_femelle from public.oiseaux where id = new.femelle_id;

  if sexe_male <> 'male' then
    raise exception 'L''oiseau désigné comme mâle du couple n''a pas le sexe "male"';
  end if;
  if sexe_femelle <> 'femelle' then
    raise exception 'L''oiseau désigné comme femelle du couple n''a pas le sexe "femelle"';
  end if;
  if eleveur_male <> new.eleveur_id or eleveur_femelle <> new.eleveur_id then
    raise exception 'Les deux oiseaux du couple doivent appartenir au même éleveur que le couple';
  end if;

  return new;
end;
$$;

create trigger trg_valider_couple
  before insert or update of male_id, femelle_id, eleveur_id on public.couples
  for each row execute function public.valider_couple();
