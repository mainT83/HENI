-- =============================================================================
-- OISEAUX
-- =============================================================================

create table public.oiseaux (
  id uuid primary key default gen_random_uuid(),
  eleveur_id uuid not null references public.profiles (id) on delete cascade,

  numero_bague text not null,
  nom text,
  espece_id uuid not null references public.especes (id),
  race text,
  mutation text,
  sexe text not null default 'indetermine' check (sexe in ('male', 'femelle', 'indetermine')),
  date_naissance date,
  eleveur_origine text,

  pere_id uuid references public.oiseaux (id) on delete set null,
  mere_id uuid references public.oiseaux (id) on delete set null,

  statut text not null default 'jeune' check (statut in ('reproducteur', 'jeune', 'a_vendre', 'vendu', 'decede')),
  photo_url text,
  notes text,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint numero_bague_unique_par_eleveur unique (eleveur_id, numero_bague),
  constraint pere_pas_soi_meme check (pere_id is null or pere_id <> id),
  constraint mere_pas_soi_meme check (mere_id is null or mere_id <> id),
  constraint pere_different_mere check (pere_id is null or mere_id is null or pere_id <> mere_id)
);

comment on table public.oiseaux is 'Fiche individuelle de chaque oiseau, avec généalogie (pere_id/mere_id auto-référencés)';

create index idx_oiseaux_eleveur on public.oiseaux (eleveur_id);
create index idx_oiseaux_pere on public.oiseaux (pere_id);
create index idx_oiseaux_mere on public.oiseaux (mere_id);
create index idx_oiseaux_statut on public.oiseaux (eleveur_id, statut);
create index idx_oiseaux_espece on public.oiseaux (espece_id);

alter table public.oiseaux enable row level security;

create policy "oiseaux gérés uniquement par leur éleveur"
  on public.oiseaux for all
  using (auth.uid() = eleveur_id)
  with check (auth.uid() = eleveur_id);

create trigger trg_oiseaux_updated_at
  before update on public.oiseaux
  for each row execute function public.set_updated_at();

-- Cohérence généalogique : le sexe du père/de la mère doit correspondre,
-- et un parent doit être né avant son enfant (évite les cycles absurdes)
create function public.valider_parents_oiseau()
returns trigger
language plpgsql
as $$
declare
  sexe_pere text;
  sexe_mere text;
  naissance_pere date;
  naissance_mere date;
begin
  if new.pere_id is not null then
    select sexe, date_naissance into sexe_pere, naissance_pere
    from public.oiseaux where id = new.pere_id;

    if sexe_pere = 'femelle' then
      raise exception 'Le père désigné (%) est enregistré comme femelle', new.pere_id;
    end if;
    if naissance_pere is not null and new.date_naissance is not null and naissance_pere >= new.date_naissance then
      raise exception 'Le père doit être né avant son descendant';
    end if;
  end if;

  if new.mere_id is not null then
    select sexe, date_naissance into sexe_mere, naissance_mere
    from public.oiseaux where id = new.mere_id;

    if sexe_mere = 'male' then
      raise exception 'La mère désignée (%) est enregistrée comme mâle', new.mere_id;
    end if;
    if naissance_mere is not null and new.date_naissance is not null and naissance_mere >= new.date_naissance then
      raise exception 'La mère doit être née avant son descendant';
    end if;
  end if;

  return new;
end;
$$;

create trigger trg_valider_parents_oiseau
  before insert or update of pere_id, mere_id, date_naissance on public.oiseaux
  for each row execute function public.valider_parents_oiseau();

-- Historique des événements d'un oiseau (achat, vente, changement de statut, etc.)
create table public.oiseau_historique (
  id uuid primary key default gen_random_uuid(),
  oiseau_id uuid not null references public.oiseaux (id) on delete cascade,
  type_evenement text not null,
  description text,
  date_evenement date not null default current_date,
  created_at timestamptz not null default now()
);

create index idx_oiseau_historique_oiseau on public.oiseau_historique (oiseau_id, date_evenement desc);

alter table public.oiseau_historique enable row level security;

create policy "historique géré via l'oiseau de son éleveur"
  on public.oiseau_historique for all
  using (exists (
    select 1 from public.oiseaux o
    where o.id = oiseau_historique.oiseau_id and o.eleveur_id = auth.uid()
  ))
  with check (exists (
    select 1 from public.oiseaux o
    where o.id = oiseau_historique.oiseau_id and o.eleveur_id = auth.uid()
  ));

-- Journalise automatiquement chaque changement de statut
create function public.log_changement_statut_oiseau()
returns trigger
language plpgsql
as $$
begin
  if tg_op = 'UPDATE' and old.statut is distinct from new.statut then
    insert into public.oiseau_historique (oiseau_id, type_evenement, description)
    values (new.id, 'changement_statut', old.statut || ' -> ' || new.statut);
  end if;
  return new;
end;
$$;

create trigger trg_log_changement_statut
  after update of statut on public.oiseaux
  for each row execute function public.log_changement_statut_oiseau();
