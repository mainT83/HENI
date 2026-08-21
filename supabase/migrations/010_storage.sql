-- =============================================================================
-- STOCKAGE : bucket pour les photos d'oiseaux
-- Convention de chemin : {eleveur_id}/{oiseau_id}.jpg — permet des policies
-- RLS simples basées sur le premier segment du chemin.
-- =============================================================================

insert into storage.buckets (id, name, public)
values ('photos-oiseaux', 'photos-oiseaux', true)
on conflict (id) do nothing;

drop policy if exists "photos oiseaux visibles publiquement (lecture seule)" on storage.objects;
create policy "photos oiseaux visibles publiquement (lecture seule)"
  on storage.objects for select
  using (bucket_id = 'photos-oiseaux');

drop policy if exists "un éleveur ne dépose des photos que dans son propre dossier" on storage.objects;
create policy "un éleveur ne dépose des photos que dans son propre dossier"
  on storage.objects for insert
  with check (
    bucket_id = 'photos-oiseaux'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "un éleveur ne modifie que ses propres photos" on storage.objects;
create policy "un éleveur ne modifie que ses propres photos"
  on storage.objects for update
  using (
    bucket_id = 'photos-oiseaux'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "un éleveur ne supprime que ses propres photos" on storage.objects;
create policy "un éleveur ne supprime que ses propres photos"
  on storage.objects for delete
  using (
    bucket_id = 'photos-oiseaux'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
