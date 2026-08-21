-- =============================================================================
-- LIMITE DU PLAN GRATUIT : 5 couples maximum tant que l'éleveur n'est pas
-- passé en premium. Appliquée par trigger (pas seulement côté appli) pour
-- rester fiable même via un appel API direct.
-- =============================================================================

alter table public.profiles add column if not exists is_premium boolean not null default false;

comment on column public.profiles.is_premium is 'true si l''éleveur a payé pour dépasser les limites du plan gratuit (ex: plus de 5 couples)';

create or replace function public.verifier_limite_couples_gratuit()
returns trigger
language plpgsql
as $$
declare
  est_premium boolean;
  nb_couples int;
begin
  select is_premium into est_premium from public.profiles where id = new.eleveur_id;

  if coalesce(est_premium, false) then
    return new;
  end if;

  select count(*) into nb_couples from public.couples where eleveur_id = new.eleveur_id;

  if nb_couples >= 5 then
    raise exception 'limite_plan_gratuit: 5 couples maximum sur le plan gratuit, passez en premium pour continuer'
      using errcode = 'P0001';
  end if;

  return new;
end;
$$;

drop trigger if exists trg_limite_couples_gratuit on public.couples;
create trigger trg_limite_couples_gratuit
  before insert on public.couples
  for each row execute function public.verifier_limite_couples_gratuit();
