-- =============================================================================
-- TABLEAU DE BORD : tendance mensuelle œufs pondus / poussins éclos, pour le
-- graphique du dashboard (inspiré d'AviBreed Pro, mais sur données réelles).
-- =============================================================================

create or replace function public.tendance_mensuelle(p_eleveur_id uuid default auth.uid(), p_nb_mois int default 6)
returns table (
  mois date,
  oeufs_pondus bigint,
  poussins_eclos bigint
)
language sql
stable
security invoker
as $$
  with mois_serie as (
    select date_trunc('month', current_date)::date - (n || ' months')::interval as mois
    from generate_series(p_nb_mois - 1, 0, -1) as n
  ),
  pontes_par_mois as (
    select date_trunc('month', date_ponte)::date as mois, sum(nombre_oeufs) as total
    from public.pontes
    where eleveur_id = p_eleveur_id
    group by 1
  ),
  eclosions_par_mois as (
    select date_trunc('month', e.date_eclosion)::date as mois, sum(e.nombre_poussins) as total
    from public.eclosions e
    where e.eleveur_id = p_eleveur_id
    group by 1
  )
  select
    ms.mois::date,
    coalesce(pm.total, 0) as oeufs_pondus,
    coalesce(em.total, 0) as poussins_eclos
  from mois_serie ms
  left join pontes_par_mois pm on pm.mois = ms.mois::date
  left join eclosions_par_mois em on em.mois = ms.mois::date
  order by ms.mois;
$$;

comment on function public.tendance_mensuelle is 'Œufs pondus et poussins éclos par mois, sur les p_nb_mois derniers mois, pour le graphique du tableau de bord';
