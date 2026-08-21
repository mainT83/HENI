-- =============================================================================
-- RESET COMPLET : supprime tout ce que les migrations 001-010 créent, pour
-- repartir d'une base propre après un état incohérent (migrations lancées
-- dans le désordre / partiellement). Ne fait PAS partie de la séquence
-- normale de migration — à lancer une seule fois, manuellement, en cas de
-- besoin, puis re-exécuter 001 à 010 dans l'ordre.
-- =============================================================================

-- Trigger sur auth.users : pas supprimé par le cascade sur public.profiles
-- puisqu'il est défini sur une table qu'on ne supprime pas.
drop trigger if exists on_auth_user_created on auth.users;

-- Tables (cascade supprime policies, index, triggers et contraintes liés)
drop table if exists public.oiseau_historique cascade;
drop table if exists public.eclosions cascade;
drop table if exists public.pontes cascade;
drop table if exists public.notifications cascade;
drop table if exists public.couples cascade;
drop table if exists public.oiseaux cascade;
drop table if exists public.especes cascade;
drop table if exists public.profiles cascade;

-- Vue et fonctions indépendantes des tables
drop view if exists public.couples_stats cascade;
drop function if exists public.dashboard_stats(uuid) cascade;
drop function if exists public.consanguinite_oiseau(uuid, int) cascade;
drop function if exists public.niveau_risque_consanguinite(uuid, uuid, int) cascade;
drop function if exists public.coefficient_consanguinite(uuid, uuid, int) cascade;
drop function if exists public.freres_soeurs(uuid) cascade;
drop function if exists public.descendants(uuid, int) cascade;
drop function if exists public.ancetres(uuid, int) cascade;
drop function if exists public.valider_couple() cascade;
drop function if exists public.handle_new_user() cascade;
drop function if exists public.set_updated_at() cascade;

-- Stockage : seules les policies sont supprimées (la suppression directe des
-- lignes storage.buckets/storage.objects est bloquée par Supabase — inutile
-- de toute façon, l'insert du bucket dans 010_storage.sql est idempotent).
drop policy if exists "photos oiseaux visibles publiquement (lecture seule)" on storage.objects;
drop policy if exists "un éleveur ne dépose des photos que dans son propre dossier" on storage.objects;
drop policy if exists "un éleveur ne modifie que ses propres photos" on storage.objects;
drop policy if exists "un éleveur ne supprime que ses propres photos" on storage.objects;
