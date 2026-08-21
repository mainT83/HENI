-- =============================================================================
-- TRAITEMENTS
-- Suivi médical par oiseau (vaccins, vermifuges, antiparasitaires...) avec
-- rappel optionnel pour la prochaine dose. 'traitement' et 'vaccination'
-- étaient déjà prévus dans notifications_type_check (005) mais jamais utilisés.
-- =============================================================================

create table public.traitements (
  id uuid primary key default gen_random_uuid(),
  oiseau_id uuid not null references public.oiseaux (id) on delete cascade,
  eleveur_id uuid not null references public.profiles (id) on delete cascade,

  type text not null check (type in ('vaccin', 'vermifuge', 'antiparasitaire', 'antibiotique', 'vitamine', 'autre')),
  nom text not null,
  description text,

  date_administration date not null default current_date,
  date_rappel date,

  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.traitements is 'Traitement médical administré à un oiseau, avec rappel optionnel pour la prochaine dose';

create index idx_traitements_oiseau on public.traitements (oiseau_id);
create index idx_traitements_eleveur on public.traitements (eleveur_id, date_rappel);

alter table public.traitements enable row level security;

create policy "traitements gérés uniquement par leur éleveur"
  on public.traitements for all
  using (auth.uid() = eleveur_id)
  with check (auth.uid() = eleveur_id);

create trigger trg_traitements_updated_at
  before update on public.traitements
  for each row execute function public.set_updated_at();

-- Renseigne eleveur_id automatiquement depuis l'oiseau (évite l'incohérence)
create function public.renseigner_eleveur_traitement()
returns trigger
language plpgsql
as $$
begin
  select eleveur_id into new.eleveur_id from public.oiseaux where id = new.oiseau_id;
  return new;
end;
$$;

create trigger trg_renseigner_eleveur_traitement
  before insert on public.traitements
  for each row execute function public.renseigner_eleveur_traitement();

-- Notification automatique à la date de rappel (prochaine dose / suivi)
create function public.notifier_rappel_traitement()
returns trigger
language plpgsql
as $$
begin
  if new.date_rappel is not null then
    insert into public.notifications (eleveur_id, type, titre, message, date_prevue, entite_type, entite_id)
    values (
      new.eleveur_id,
      'traitement',
      'Rappel traitement',
      new.nom || ' : rappel prévu',
      new.date_rappel::timestamptz,
      'traitement',
      new.id
    );
  end if;
  return new;
end;
$$;

create trigger trg_notifier_rappel_traitement
  after insert on public.traitements
  for each row execute function public.notifier_rappel_traitement();

-- Ajoute le compteur de rappels de traitement à venir (7 prochains jours)
-- au tableau de bord. Le type de retour change (nouvelle colonne) : il faut
-- supprimer l'ancienne fonction avant de la recréer.
drop function if exists public.dashboard_stats(uuid);

create function public.dashboard_stats(p_eleveur_id uuid default auth.uid())
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
        and date_rappel between current_date and current_date + interval '7 days'
    );
$$;

comment on function public.dashboard_stats is 'Chiffres clés du tableau de bord pour l''éleveur connecté (ou l''éleveur passé en paramètre, soumis à la RLS des tables sous-jacentes)';
