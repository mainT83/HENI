-- =============================================================================
-- NOUVELLE DÉFINITION DU PLAN GRATUIT : 10 oiseaux maximum (remplace
-- l'ancienne limite de 5 couples, migration 011). Le suivi généalogique
-- (arbre généalogique + coefficient de consanguinité) reste, lui, réservé
-- au premium — géré côté application via profiles.is_premium.
-- =============================================================================

drop trigger if exists trg_limite_couples_gratuit on public.couples;
drop function if exists public.verifier_limite_couples_gratuit();

create function public.verifier_limite_oiseaux_gratuit()
returns trigger
language plpgsql
as $$
declare
  est_premium boolean;
  nb_oiseaux int;
begin
  select is_premium into est_premium from public.profiles where id = new.eleveur_id;

  if coalesce(est_premium, false) then
    return new;
  end if;

  select count(*) into nb_oiseaux from public.oiseaux where eleveur_id = new.eleveur_id;

  if nb_oiseaux >= 10 then
    raise exception 'limite_plan_gratuit: 10 oiseaux maximum sur le plan gratuit, passez en premium pour continuer'
      using errcode = 'P0001';
  end if;

  return new;
end;
$$;

create trigger trg_limite_oiseaux_gratuit
  before insert on public.oiseaux
  for each row execute function public.verifier_limite_oiseaux_gratuit();
