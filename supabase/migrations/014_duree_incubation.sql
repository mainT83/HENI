-- =============================================================================
-- Durée d'incubation par espèce, pour calculer automatiquement la date
-- d'éclosion prévue d'une ponte (date_ponte + duree_incubation_jours).
-- =============================================================================

alter table public.especes add column if not exists duree_incubation_jours int;

update public.especes set duree_incubation_jours = 13 where code = 'canari_domestique';
update public.especes set duree_incubation_jours = 12 where code = 'chardonneret_elegant';
update public.especes set duree_incubation_jours = 18 where code = 'perruche_ondulee';
update public.especes set duree_incubation_jours = 21 where code = 'perruche_calopsitte';
update public.especes set duree_incubation_jours = 22 where code = 'perruche_agapornis';
update public.especes set duree_incubation_jours = 29 where code = 'perroquet_gris_gabon';
update public.especes set duree_incubation_jours = 26 where code = 'perroquet_ara';
update public.especes set duree_incubation_jours = 18 where code = 'pigeon_voyageur';
update public.especes set duree_incubation_jours = 13 where code = 'colombe_diamant';
-- 'exotique_autre' reste NULL : pas de durée générique fiable, l'éleveur
-- devra saisir la date d'éclosion prévue manuellement pour cette entrée.

comment on column public.especes.duree_incubation_jours is 'Durée d''incubation typique en jours, utilisée pour pré-calculer la date d''éclosion prévue d''une ponte';
