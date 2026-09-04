-- =============================================================================
-- La migration 023 avait lié "traitements_a_venir" à l'état lu/non-lu de la
-- notification de rappel associée : dès que l'éleveur consultait la
-- notification (ou le traitement), le compteur retombait à 0 même si la
-- date de rappel elle-même était encore dans plusieurs jours. On revient à
-- un comptage basé uniquement sur la date de rappel (comme en 022) : le
-- compteur reste tant que le rappel est dû ou en retard, et ne disparaît
-- que si le traitement est supprimé ou la date passée. "notifications_non_lues"
-- reste un compteur séparé, indépendant de celui-ci.
-- =============================================================================

create or replace function public.dashboard_stats(p_eleveur_id uuid default auth.uid())
returns table (
  total_oiseaux bigint,
  couples_actifs bigint,
  jeunes_en_elevage bigint,
  pontes_en_cours bigint,
  taux_eclosion_global numeric,
  notifications_non_lues bigint,
  traitements_a_venir bigint
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
    (select count(*) from public.notifications where eleveur_id = p_eleveur_id and lu = false),
    (
      select count(*) from public.traitements
      where eleveur_id = p_eleveur_id
        and date_rappel is not null
        and date_rappel <= current_date + interval '7 days'
    );
$$;
