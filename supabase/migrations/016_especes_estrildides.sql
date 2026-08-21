-- =============================================================================
-- Nouvelles espèces : estrildidés (diamants, capucins...) et Agapornis par
-- espèce. Corrige aussi une erreur de nommage antérieure : 'colombe_diamant'
-- avait été mal traduit en français ("Diamant mandarin" désigne en réalité
-- le Diamant mandarin/Zebra Finch, un estrildidé — pas une colombe).
-- =============================================================================

alter table public.especes drop constraint especes_categorie_check;
alter table public.especes add constraint especes_categorie_check
  check (categorie in ('canari', 'chardonneret', 'perruche', 'perroquet', 'colombide', 'estrildide', 'exotique', 'autre'));

-- Correction du nom français erroné de 'colombe_diamant' (c'est une colombe,
-- pas le "diamant mandarin" qui est un estrildidé — ajouté séparément ci-dessous).
update public.especes set nom_fr = 'Colombine diamant' where code = 'colombe_diamant';

insert into public.especes (code, nom_fr, nom_ar, nom_en, categorie) values
  ('estrildide_diamant_mandarin', 'Diamant mandarin', 'دياموند مانداران', 'Zebra Finch', 'estrildide'),
  ('estrildide_moineau_japon', 'Moineau du Japon (Lonchura domestica)', 'عصفور اليابان', 'Society Finch', 'estrildide'),
  ('estrildide_diamant_longue_queue', 'Diamant à longue queue, bec jaune (Poephila acuticauda acuticauda)', 'دياموند طويل الذيل', 'Long-tailed Finch', 'estrildide'),
  ('estrildide_diamant_longue_queue_heck', 'Diamant à longue queue de Heck, bec rouge (Poephila acuticauda hecki)', 'دياموند هيك', 'Heck''s Long-tailed Finch', 'estrildide'),
  ('estrildide_diamant_gouttelettes', 'Diamant à gouttelettes (Stagonopleura guttata)', 'دياموند منقط', 'Diamond Firetail', 'estrildide'),
  ('estrildide_diamant_bavette', 'Diamant à bavette (Poephila cincta)', 'دياموند ذو الصدرية', 'Black-throated Finch', 'estrildide'),
  ('estrildide_diamant_modeste', 'Diamant modeste (Neochmia modesta)', 'دياموند متواضع', 'Plum-headed Finch', 'estrildide'),
  ('estrildide_diamant_ruficauda', 'Diamant ruficauda, à queue rousse (Neochmia ruficauda)', 'دياموند ذو الذيل الأحمر', 'Star Finch', 'estrildide'),
  ('estrildide_diamant_bichenov', 'Diamant de Bichenov (Taeniopygia bichenovii)', 'دياموند بيشونوف', 'Double-barred Finch', 'estrildide'),
  ('estrildide_diamant_psittaculaire', 'Diamant psittaculaire, de Nouméa (Erythrura psittacea)', 'دياموند نوميا', 'Red-throated Parrotfinch', 'estrildide'),
  ('estrildide_diamant_kittlitz', 'Diamant de Kittlitz (Erythrura trichroa)', 'دياموند كيتليتز', 'Blue-faced Parrotfinch', 'estrildide'),
  ('estrildide_padda', 'Padda (Lonchura oryzivora)', 'بادا', 'Java Sparrow', 'estrildide'),
  ('estrildide_capucin_bec_argent', 'Capucin bec d''argent (Lonchura cantans)', 'كابوسين فضي المنقار', 'African Silverbill', 'estrildide'),
  ('estrildide_capucin_bec_plomb', 'Capucin bec de plomb (Lonchura malabarica)', 'كابوسين رصاصي المنقار', 'Indian Silverbill', 'estrildide'),
  ('estrildide_cou_coupe', 'Cou-coupé (Amadina fasciata)', 'مقطوع الرقبة', 'Cut-throat Finch', 'estrildide'),
  ('estrildide_amadina_tete_rouge', 'Amadina à tête rouge (Amadina erythrocephala)', 'أمادينا أحمر الرأس', 'Red-headed Finch', 'estrildide'),

  ('perruche_agapornis_roseicollis', 'Agapornis roseicollis', 'أغابورنيس روزيكوليس', 'Rosy-faced Lovebird', 'perruche'),
  ('perruche_agapornis_fischeri', 'Agapornis fischeri', 'أغابورنيس فيشري', 'Fischer''s Lovebird', 'perruche'),
  ('perruche_agapornis_personatus', 'Agapornis personatus', 'أغابورنيس بيرسوناتوس', 'Yellow-collared Lovebird', 'perruche'),
  ('perruche_agapornis_lilianae', 'Agapornis lilianae', 'أغابورنيس ليليانا', 'Lilian''s Lovebird', 'perruche'),
  ('perruche_agapornis_nigrigenis', 'Agapornis nigrigenis', 'أغابورنيس نيغريجينيس', 'Black-cheeked Lovebird', 'perruche'),
  ('perruche_agapornis_taranta', 'Agapornis taranta', 'أغابورنيس تارانتا', 'Black-winged Lovebird', 'perruche'),
  ('perruche_agapornis_pullarius', 'Agapornis pullarius', 'أغابورنيس بولاريوس', 'Red-headed Lovebird', 'perruche'),
  ('perruche_agapornis_canus', 'Agapornis canus', 'أغابورنيس كانوس', 'Grey-headed Lovebird', 'perruche')
on conflict (code) do nothing;
