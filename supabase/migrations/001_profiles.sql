-- =============================================================================
-- PROFILS ÉLEVEUR
-- Un profil par utilisateur authentifié (auth.users). Toutes les autres
-- tables référencent profiles(id) pour l'isolation multi-éleveur (RLS).
-- =============================================================================

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  nom_elevage text,
  prenom text,
  nom text,
  telephone text,
  langue text not null default 'fr' check (langue in ('fr', 'ar', 'en')),
  pays text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.profiles is 'Profil éleveur, un par utilisateur auth.users';

alter table public.profiles enable row level security;

create policy "profil visible par son propriétaire"
  on public.profiles for select
  using (auth.uid() = id);

create policy "profil modifiable par son propriétaire"
  on public.profiles for update
  using (auth.uid() = id);

-- Crée automatiquement un profil vide à l'inscription (email, Google, Apple
-- passent tous par auth.users, ce trigger couvre les 3 méthodes)
create function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, prenom, nom)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'given_name', ''),
    coalesce(new.raw_user_meta_data ->> 'family_name', '')
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Maintient updated_at à jour automatiquement (réutilisée par les autres tables)
create function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger trg_profiles_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();
