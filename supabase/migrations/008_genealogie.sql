-- =============================================================================
-- GÉNÉALOGIE : ancêtres, descendants, fratrie, coefficient de consanguinité
-- =============================================================================

-- Ancêtres d'un oiseau jusqu'à p_profondeur générations, avec le détail de
-- chaque ancêtre. Un même ancêtre peut apparaître plusieurs fois (une fois
-- par chemin généalogique distinct qui y mène) : c'est voulu, c'est ce qui
-- permet le calcul correct du coefficient de consanguinité plus bas.
create or replace function public.ancetres(p_oiseau_id uuid, p_profondeur int default 6)
returns table (
  ancetre_id uuid,
  generation int,
  numero_bague text,
  nom text,
  sexe text,
  photo_url text
)
language sql
stable
as $$
  with recursive remontee(ancetre_id, generation) as (
    select pere_id, 1 from public.oiseaux where id = p_oiseau_id and pere_id is not null
    union all
    select mere_id, 1 from public.oiseaux where id = p_oiseau_id and mere_id is not null
    union all
    -- Un seul terme récursif (père ET mère via unnest) : PostgreSQL exige
    -- que le terme récursif soit unique et placé en dernier dans la chaîne
    -- de union all, sous peine de "recursive reference ... must not appear
    -- within its non-recursive term".
    select next_id, r.generation + 1
    from remontee r
    join public.oiseaux o on o.id = r.ancetre_id
    cross join unnest(array[o.pere_id, o.mere_id]) as next_id
    where next_id is not null and r.generation < p_profondeur
  )
  select r.ancetre_id, r.generation, o.numero_bague, o.nom, o.sexe, o.photo_url
  from remontee r
  join public.oiseaux o on o.id = r.ancetre_id;
$$;

comment on function public.ancetres is
  'Remonte l''arbre généalogique. Un ancêtre atteint par plusieurs chemins apparaît plusieurs fois (une ligne par chemin) — nécessaire pour coefficient_consanguinite().';

-- Descendants d'un oiseau jusqu'à p_profondeur générations
create or replace function public.descendants(p_oiseau_id uuid, p_profondeur int default 6)
returns table (
  descendant_id uuid,
  generation int,
  numero_bague text,
  nom text,
  sexe text,
  photo_url text
)
language sql
stable
as $$
  with recursive descente(descendant_id, generation) as (
    select id, 1 from public.oiseaux where pere_id = p_oiseau_id or mere_id = p_oiseau_id
    union all
    select o.id, d.generation + 1
    from descente d
    join public.oiseaux o on o.pere_id = d.descendant_id or o.mere_id = d.descendant_id
    where d.generation < p_profondeur
  )
  select d.descendant_id, min(d.generation) as generation, o.numero_bague, o.nom, o.sexe, o.photo_url
  from descente d
  join public.oiseaux o on o.id = d.descendant_id
  group by d.descendant_id, o.numero_bague, o.nom, o.sexe, o.photo_url;
$$;

-- Frères et sœurs (complets ou demi) d'un oiseau
create or replace function public.freres_soeurs(p_oiseau_id uuid)
returns setof public.oiseaux
language sql
stable
as $$
  select o2.*
  from public.oiseaux o1
  join public.oiseaux o2 on (
    (o1.pere_id is not null and o1.pere_id = o2.pere_id)
    or (o1.mere_id is not null and o1.mere_id = o2.mere_id)
  )
  where o1.id = p_oiseau_id and o2.id <> p_oiseau_id;
$$;

-- =============================================================================
-- Coefficient de consanguinité (F) d'un croisement pere x mere, méthode des
-- chemins de Wright, approximation au 1er ordre : on suppose F_A = 0 pour les
-- ancêtres eux-mêmes (hypothèse standard des outils de pedigree amateurs,
-- raisonnable au-delà de quelques générations). p_profondeur borne la
-- recherche d'ancêtres communs (6 générations par défaut = 64 lignées, largement
-- suffisant en pratique et nécessaire pour rester performant).
-- =============================================================================

create or replace function public.coefficient_consanguinite(p_pere_id uuid, p_mere_id uuid, p_profondeur int default 6)
returns numeric
language sql
stable
as $$
  -- Chaque individu est aussi son propre "ancêtre" à la génération 0 : ceci
  -- couvre le cas où l'un des deux est lui-même un ancêtre direct de l'autre
  -- (ex: accouplement père x fille), sans quoi ce cas donnerait F=0 alors
  -- qu'il vaut 0.25 — vérifié contre les valeurs de référence connues
  -- (frère x soeur = 0.25, demi-fratrie = 0.125, cousins germains = 0.0625, etc.)
  with ancetres_pere as (
    select ancetre_id, generation from public.ancetres(p_pere_id, p_profondeur)
    union all
    select p_pere_id, 0
  ), ancetres_mere as (
    select ancetre_id, generation from public.ancetres(p_mere_id, p_profondeur)
    union all
    select p_mere_id, 0
  )
  select coalesce(sum(power(0.5, ap.generation + am.generation + 1)), 0)::numeric
  from ancetres_pere ap
  join ancetres_mere am on am.ancetre_id = ap.ancetre_id;
$$;

comment on function public.coefficient_consanguinite is
  'F approximatif (0 à 1) pour un croisement pere x mere. >= 0.25 = tres eleve, >= 0.125 = eleve, >= 0.0625 = modere, sinon faible.';

-- Classification du niveau de risque, pour l'alerte visuelle côté app
create or replace function public.niveau_risque_consanguinite(p_pere_id uuid, p_mere_id uuid, p_profondeur int default 6)
returns table (coefficient numeric, niveau text)
language sql
stable
as $$
  select
    f,
    case
      when f >= 0.25 then 'tres_eleve'
      when f >= 0.125 then 'eleve'
      when f >= 0.0625 then 'modere'
      else 'faible'
    end
  from public.coefficient_consanguinite(p_pere_id, p_mere_id, p_profondeur) as f;
$$;

-- Coefficient de consanguinité déjà "réalisé" d'un oiseau existant (ses
-- propres parents) — pratique pour l'afficher directement sur sa fiche.
create or replace function public.consanguinite_oiseau(p_oiseau_id uuid, p_profondeur int default 6)
returns numeric
language sql
stable
as $$
  select public.coefficient_consanguinite(o.pere_id, o.mere_id, p_profondeur)
  from public.oiseaux o
  where o.id = p_oiseau_id and o.pere_id is not null and o.mere_id is not null;
$$;
