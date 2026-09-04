-- =============================================================================
-- Le numéro de bague est en fait scindé par diamètre, et le diamètre dépend
-- de l'espèce (parfois du groupe d'espèces) — deux oiseaux d'espèces
-- différentes peuvent légitimement porter le même numéro la même année,
-- chez le même éleveur/souche. L'année est elle aussi encodée sur la bague
-- (via un code couleur qui change chaque année), donc le même numéro peut
-- aussi revenir d'une année sur l'autre pour la même espèce.
--
-- La contrainte précédente (éleveur + bague + souche) ne suffit donc pas :
-- on ajoute l'espèce et l'année de naissance. Un oiseau sans date de
-- naissance connue n'est pas contraint par l'année (NULL = toujours
-- distinct en SQL), ce qui reste préférable à un faux rejet.
-- =============================================================================

alter table public.oiseaux drop constraint numero_bague_unique_par_eleveur;

create unique index numero_bague_unique_par_eleveur
  on public.oiseaux (eleveur_id, numero_bague, numero_souche, espece_id, extract(year from date_naissance));
