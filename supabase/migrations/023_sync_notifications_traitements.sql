-- =============================================================================
-- "Rappels de traitement" restait affiché au tableau de bord même après que
-- l'éleveur ait ouvert (et donc marqué comme lue) la notification de rappel
-- correspondante : les deux compteurs venaient de sources différentes
-- (notifications.lu vs date_rappel de traitements). On les fait maintenant
-- correspondre : un traitement ne compte dans "à venir" que tant que sa
-- notification de rappel n'a pas été lue.
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
      select count(*) from public.traitements t
      where t.eleveur_id = p_eleveur_id
        and t.date_rappel is not null
        and t.date_rappel <= current_date + interval '7 days'
        and exists (
          select 1 from public.notifications n
          where n.entite_type = 'traitement'
            and n.entite_id = t.id
            and n.lu = false
        )
    );
$$;
