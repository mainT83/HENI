-- =============================================================================
-- Le formulaire d'inscription ne demandait ni prénom ni nom : tous les
-- profils créés jusqu'ici ont prenom/nom vides, et le "Display name" de
-- Supabase Auth (users list) reste "-" pour les inscriptions par email.
--
-- Le champ "Nom" ajouté au formulaire d'inscription envoie désormais
-- raw_user_meta_data.full_name à la création du compte ; ce trigger le
-- récupère en repli si given_name/family_name (Google OAuth) sont absents.
-- =============================================================================

create or replace function public.handle_new_user()
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
    coalesce(new.raw_user_meta_data ->> 'family_name', new.raw_user_meta_data ->> 'full_name', '')
  );
  return new;
end;
$$;
