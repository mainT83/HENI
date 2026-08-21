-- =============================================================================
-- STATISTIQUES : performance des couples + tableau de bord
-- (uniquement ce qui est calculable avec le périmètre MVP actuel ; le taux de
-- sevrage et la rentabilité rejoindront ces vues avec les modules Sevrage et
-- Finance, hors MVP pour l'instant)
-- =============================================================================

create or replace view public.couples_stats as
select
  c.id as couple_id,
  c.eleveur_id,
  c.male_id,
  c.femelle_id,
  count(distinct p.id) as nombre_pontes,
  coalesce(sum(p.nombre_oeufs), 0) as total_oeufs,
  coalesce(sum(p.oeufs_fecondes), 0) as total_oeufs_fecondes,
  coalesce(sum(e.nombre_poussins), 0) as total_poussins,
  coalesce(sum(e.mortalite), 0) as total_mortalite,
  case when sum(p.nombre_oeufs) > 0
    then round(coalesce(sum(e.nombre_poussins), 0)::numeric / sum(p.nombre_oeufs) * 100, 1)
    else null
  end as taux_eclosion_pct,
  -- Score simple sur 100 : combine volume (nb pontes) et qualité (taux d'éclosion)
  case when sum(p.nombre_oeufs) > 0
    then round(
      least(count(distinct p.id), 5) * 10  -- jusqu'à 50 pts pour l'expérience du couple
      + coalesce(sum(e.nombre_poussins), 0)::numeric / sum(p.nombre_oeufs) * 50  -- jusqu'à 50 pts pour le taux d'éclosion
    , 1)
    else 0
  end as score_performance
from public.couples c
left join public.pontes p on p.couple_id = c.id
left join public.eclosions e on e.ponte_id = p.id
group by c.id, c.eleveur_id, c.male_id, c.femelle_id;

comment on view public.couples_stats is 'Statistiques de performance par couple : pontes, taux d''éclosion, score /100';

-- RLS d'une vue = RLS des tables sous-jacentes (couples), donc rien à ajouter
-- ici tant que la vue n'est pas "security definer" (elle ne l'est pas).

create or replace function public.dashboard_stats(p_eleveur_id uuid default auth.uid())
returns table (
  total_oiseaux bigint,
  couples_actifs bigint,
  jeunes_en_elevage bigint,
  pontes_en_cours bigint,
  taux_eclosion_global numeric,
  notifications_non_lues bigint
)
language sql
stable
security invoker
as $$
  select
    (select count(*) from public.oiseaux where eleveur_id = p_eleveur_id and statut <> 'decede'),
    (select count(*) from public.couples where eleveur_id = p_eleveur_id and actif = true),
    (select count(*) from public.oiseaux where eleveur_id = p_eleveur_id and statut = 'jeune'),
    (select count(*) from public.pontes where eleveur_id = p_eleveur_id and statut = 'en_cours'),
    (
      select case when sum(nombre_oeufs) > 0
        then round(coalesce(sum(p_ec.total_poussins), 0)::numeric / sum(nombre_oeufs) * 100, 1)
        else null end
      from public.pontes p
      left join (
        select ponte_id, sum(nombre_poussins) as total_poussins
        from public.eclosions group by ponte_id
      ) p_ec on p_ec.ponte_id = p.id
      where p.eleveur_id = p_eleveur_id
    ),
    (select count(*) from public.notifications where eleveur_id = p_eleveur_id and lu = false);
$$;

comment on function public.dashboard_stats is 'Chiffres clés du tableau de bord pour l''éleveur connecté (ou l''éleveur passé en paramètre, soumis à la RLS des tables sous-jacentes)';
