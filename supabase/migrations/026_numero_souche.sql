-- =============================================================================
-- Le numéro de bague seul n'est unique que par éleveur ET par souche
-- d'origine : deux oiseaux de souches différentes (ex. un oiseau né chez soi
-- et un autre acheté ailleurs) peuvent légitimement porter le même numéro de
-- bague. On ajoute le numéro de souche et on l'inclut dans la contrainte
-- d'unicité.
--
-- Chaque éleveur a son propre numéro de souche fixe (renseigné dans son
-- profil) : il est utilisé automatiquement pour les oiseaux nés chez lui
-- (créés via une éclosion). Pour un oiseau acheté/acquis ailleurs, l'éleveur
-- saisit manuellement le numéro de souche de l'éleveur d'origine.
-- =============================================================================

alter table public.profiles add column if not exists numero_souche text;

alter table public.oiseaux add column if not exists numero_souche text;

alter table public.oiseaux drop constraint numero_bague_unique_par_eleveur;
alter table public.oiseaux add constraint numero_bague_unique_par_eleveur
  unique (eleveur_id, numero_bague, numero_souche);

-- creer_jeune_depuis_eclosion renseigne automatiquement le numéro de souche
-- de l'éleveur (l'oiseau est né chez lui).
create or replace function public.creer_jeune_depuis_eclosion(
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
  v_deja_crees int;
  v_numero_souche text;
  v_nouvel_oiseau public.oiseaux;
begin
  select e.*, p.couple_id into v_eclosion
  from public.eclosions e
  join public.pontes p on p.id = e.ponte_id
  where e.id = p_eclosion_id;

  if v_eclosion is null then
    raise exception 'Éclosion introuvable: %', p_eclosion_id;
  end if;

  select count(*) into v_deja_crees from public.oiseaux where eclosion_id = p_eclosion_id;
  if v_deja_crees >= v_eclosion.nombre_poussins then
    raise exception 'limite_poussins_eclosion: % poussin(s) enregistré(s) pour cette éclosion, déjà % oiseau(x) créé(s)',
      v_eclosion.nombre_poussins, v_deja_crees
      using errcode = 'P0001';
  end if;

  select c.male_id, c.femelle_id, c.eleveur_id into v_couple
  from public.couples c
  join public.pontes p on p.couple_id = c.id
  where p.id = v_eclosion.ponte_id;

  select espece_id into v_espece_id from public.oiseaux where id = v_couple.femelle_id;
  select numero_souche into v_numero_souche from public.profiles where id = v_couple.eleveur_id;

  insert into public.oiseaux (
    eleveur_id, numero_bague, nom, espece_id, sexe,
    date_naissance, pere_id, mere_id, statut, eclosion_id, numero_souche
  ) values (
    v_couple.eleveur_id, p_numero_bague, p_nom, v_espece_id, p_sexe,
    v_eclosion.date_eclosion, v_couple.male_id, v_couple.femelle_id, 'jeune', p_eclosion_id, v_numero_souche
  )
  returning * into v_nouvel_oiseau;

  return v_nouvel_oiseau;
end;
$$;
