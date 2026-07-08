--
-- seed_bulk_data.sql — large-volume demo data (10000 records per project)
--
-- Adds 40000 project_records (10000 each to projects 7,8,9,10) on top of the
-- curated demo (seed_test_data.sql MUST be run first — this reuses its
-- keyword groups, data_groups and users).
--
-- Builds FULL Linnaean taxonomies (Kingdom > Phylum > Class > Order > Family
-- > Genus > Species) for life science (Animalia + Plantae) and paleontology
-- (fossil taxa, each species carrying its geological period). Minerals are
-- classified by Mineral Class > Species (minerals are not Linnaean), with
-- crystal system / hardness / formula on each species.
--
-- Records are generated set-based with generate_series: each gets a random
-- determination to a species, a random point geometry, dates (life science),
-- jsonb custom fields, a typed identifier and keyword classification (domain
-- + period / mineral-class / conservation / preservation).
--
-- IDEMPOTENT: guarded by the root keyword `demo-bulk-seed`. Re-running is a
-- no-op. Remove with seed_bulk_teardown.sql.
--
-- The whole load is one transaction so the deferred requires-project trigger
-- is satisfied at COMMIT.
--

SET client_encoding TO 'UTF8';

BEGIN;

DO $bulk$
DECLARE
    v_admin   bigint := 13;
    k_dom_obs bigint; k_dom_coll bigint; k_dom_paleo bigint; k_dom_min bigint;
    k_idtype  bigint; k_catalog bigint; k_accession bigint;
    k_detm    bigint; k_morph bigint; k_xrd bigint;
    k_period_p   bigint; k_minclass_p bigint;
    k_conserv_p  bigint; k_preserv_p bigint;
    dg_list bigint; dg_item bigint;
    u_a bigint; u_b bigint;
    v_sentinel bigint;

    L_animalia bigint; L_plants bigint; L_paleo bigint; L_min bigint;

    cfg RECORD;
    ranks text[];
    i int; col text; pcol_expr text;
BEGIN
    ------------------------------------------------------------------
    -- preconditions
    ------------------------------------------------------------------
    IF NOT EXISTS (SELECT 1 FROM dbnext.keyword WHERE name='demo-seed' AND id_parent IS NULL) THEN
        RAISE EXCEPTION 'curated demo seed not found — run seed_test_data.sql first';
    END IF;
    IF EXISTS (SELECT 1 FROM dbnext.keyword WHERE name='demo-bulk-seed' AND id_parent IS NULL) THEN
        RAISE NOTICE 'bulk seed already present — skipping (run seed_bulk_teardown.sql to reset)';
        RETURN;
    END IF;

    -- lookups (reuse curated vocabulary)
    SELECT id INTO k_dom_obs   FROM dbnext.keyword WHERE name='Life Science Observations' AND id_parent=40;
    SELECT id INTO k_dom_coll  FROM dbnext.keyword WHERE name='Life Science Collections'  AND id_parent=40;
    SELECT id INTO k_dom_paleo FROM dbnext.keyword WHERE name='Paleontology Collections'  AND id_parent=40;
    SELECT id INTO k_dom_min   FROM dbnext.keyword WHERE name='Mineralogy Collections'    AND id_parent=40;
    SELECT id INTO k_idtype    FROM dbnext.keyword WHERE name='Identifier Type'      AND id_parent IS NULL;
    SELECT id INTO k_catalog   FROM dbnext.keyword WHERE name='Catalog Number'       AND id_parent=k_idtype;
    SELECT id INTO k_accession FROM dbnext.keyword WHERE name='Accession Number'     AND id_parent=k_idtype;
    SELECT id INTO k_detm      FROM dbnext.keyword WHERE name='Determination Method' AND id_parent IS NULL;
    SELECT id INTO k_morph     FROM dbnext.keyword WHERE name='morphological'        AND id_parent=k_detm;
    SELECT id INTO k_xrd       FROM dbnext.keyword WHERE name='X-ray diffraction'    AND id_parent=k_detm;
    SELECT id INTO k_period_p  FROM dbnext.keyword WHERE name='Geological Period'    AND id_parent IS NULL;
    SELECT id INTO k_minclass_p FROM dbnext.keyword WHERE name='Mineral Class'       AND id_parent IS NULL;
    SELECT id INTO k_conserv_p FROM dbnext.keyword WHERE name='Conservation Status'  AND id_parent IS NULL;
    SELECT id INTO k_preserv_p FROM dbnext.keyword WHERE name='Preservation Method'  AND id_parent IS NULL;
    SELECT id INTO dg_list     FROM dbnext.data_group WHERE name='demo: taxonomy list fields';
    SELECT id INTO dg_item     FROM dbnext.data_group WHERE name='demo: taxon item fields';
    SELECT id INTO u_a         FROM dbnext.users WHERE email='maria.hofer@demo.museum';
    SELECT id INTO u_b         FROM dbnext.users WHERE email='jean.petit@demo.museum';

    INSERT INTO dbnext.keyword(name, description, id_data_group)
        VALUES ('demo-bulk-seed','marker: rows created by seed_bulk_data.sql',
                (SELECT id FROM dbnext.data_group WHERE name='demo: keyword metadata'))
        RETURNING id INTO v_sentinel;

    ------------------------------------------------------------------
    -- bulk taxonomy item_lists
    ------------------------------------------------------------------
    INSERT INTO dbnext.item_list(name, description, data, item_list_id_data_group, item_id_data_group, created_by)
    VALUES ('Animalia - full taxonomy','bulk Linnaean animal taxonomy','{}'::jsonb, dg_list, dg_item, v_admin),
           ('Plantae - full taxonomy', 'bulk Linnaean plant taxonomy', '{}'::jsonb, dg_list, dg_item, v_admin),
           ('Fossil taxa - full taxonomy','bulk fossil taxonomy w/ periods','{}'::jsonb, dg_list, dg_item, v_admin),
           ('Mineral systematics',      'bulk mineral classification',  '{}'::jsonb, dg_list, dg_item, v_admin);
    SELECT id INTO L_animalia FROM dbnext.item_list WHERE name='Animalia - full taxonomy';
    SELECT id INTO L_plants   FROM dbnext.item_list WHERE name='Plantae - full taxonomy';
    SELECT id INTO L_paleo    FROM dbnext.item_list WHERE name='Fossil taxa - full taxonomy';
    SELECT id INTO L_min      FROM dbnext.item_list WHERE name='Mineral systematics';

    INSERT INTO dbnext.item_list_keyword(id_item_list, id_keyword) VALUES
        (L_animalia,k_dom_coll),(L_plants,k_dom_coll),(L_paleo,k_dom_paleo),(L_min,k_dom_min);

    ------------------------------------------------------------------
    -- denormalised source taxonomies (one row per species, full lineage)
    ------------------------------------------------------------------
    CREATE TEMP TABLE tax_anim(kingdom text,phylum text,class text,taxon_order text,family text,genus text,species text) ON COMMIT DROP;
    INSERT INTO tax_anim VALUES
    ('Animalia','Chordata','Mammalia','Carnivora','Felidae','Panthera','Panthera leo'),
    ('Animalia','Chordata','Mammalia','Carnivora','Felidae','Panthera','Panthera tigris'),
    ('Animalia','Chordata','Mammalia','Carnivora','Felidae','Panthera','Panthera pardus'),
    ('Animalia','Chordata','Mammalia','Carnivora','Felidae','Panthera','Panthera onca'),
    ('Animalia','Chordata','Mammalia','Carnivora','Felidae','Felis','Felis silvestris'),
    ('Animalia','Chordata','Mammalia','Carnivora','Felidae','Felis','Felis catus'),
    ('Animalia','Chordata','Mammalia','Carnivora','Canidae','Canis','Canis lupus'),
    ('Animalia','Chordata','Mammalia','Carnivora','Canidae','Canis','Canis aureus'),
    ('Animalia','Chordata','Mammalia','Carnivora','Canidae','Vulpes','Vulpes vulpes'),
    ('Animalia','Chordata','Mammalia','Carnivora','Ursidae','Ursus','Ursus arctos'),
    ('Animalia','Chordata','Mammalia','Carnivora','Mustelidae','Meles','Meles meles'),
    ('Animalia','Chordata','Mammalia','Primates','Hominidae','Homo','Homo sapiens'),
    ('Animalia','Chordata','Mammalia','Primates','Hominidae','Pan','Pan troglodytes'),
    ('Animalia','Chordata','Mammalia','Primates','Hominidae','Gorilla','Gorilla gorilla'),
    ('Animalia','Chordata','Mammalia','Artiodactyla','Cervidae','Cervus','Cervus elaphus'),
    ('Animalia','Chordata','Mammalia','Artiodactyla','Cervidae','Capreolus','Capreolus capreolus'),
    ('Animalia','Chordata','Mammalia','Artiodactyla','Bovidae','Bos','Bos taurus'),
    ('Animalia','Chordata','Mammalia','Artiodactyla','Bovidae','Capra','Capra ibex'),
    ('Animalia','Chordata','Mammalia','Artiodactyla','Bovidae','Rupicapra','Rupicapra rupicapra'),
    ('Animalia','Chordata','Mammalia','Rodentia','Sciuridae','Sciurus','Sciurus vulgaris'),
    ('Animalia','Chordata','Mammalia','Chiroptera','Vespertilionidae','Myotis','Myotis myotis'),
    ('Animalia','Chordata','Aves','Passeriformes','Paridae','Parus','Parus major'),
    ('Animalia','Chordata','Aves','Passeriformes','Paridae','Cyanistes','Cyanistes caeruleus'),
    ('Animalia','Chordata','Aves','Passeriformes','Paridae','Periparus','Periparus ater'),
    ('Animalia','Chordata','Aves','Passeriformes','Muscicapidae','Erithacus','Erithacus rubecula'),
    ('Animalia','Chordata','Aves','Passeriformes','Muscicapidae','Luscinia','Luscinia megarhynchos'),
    ('Animalia','Chordata','Aves','Passeriformes','Corvidae','Corvus','Corvus corax'),
    ('Animalia','Chordata','Aves','Passeriformes','Corvidae','Corvus','Corvus corone'),
    ('Animalia','Chordata','Aves','Passeriformes','Corvidae','Pica','Pica pica'),
    ('Animalia','Chordata','Aves','Passeriformes','Fringillidae','Fringilla','Fringilla coelebs'),
    ('Animalia','Chordata','Aves','Passeriformes','Fringillidae','Carduelis','Carduelis carduelis'),
    ('Animalia','Chordata','Aves','Accipitriformes','Accipitridae','Aquila','Aquila chrysaetos'),
    ('Animalia','Chordata','Aves','Accipitriformes','Accipitridae','Buteo','Buteo buteo'),
    ('Animalia','Chordata','Aves','Strigiformes','Strigidae','Bubo','Bubo bubo'),
    ('Animalia','Chordata','Aves','Strigiformes','Strigidae','Strix','Strix aluco'),
    ('Animalia','Chordata','Aves','Anseriformes','Anatidae','Anas','Anas platyrhynchos'),
    ('Animalia','Chordata','Aves','Charadriiformes','Laridae','Larus','Larus argentatus'),
    ('Animalia','Chordata','Amphibia','Anura','Ranidae','Rana','Rana temporaria'),
    ('Animalia','Chordata','Amphibia','Anura','Bufonidae','Bufo','Bufo bufo'),
    ('Animalia','Chordata','Amphibia','Caudata','Salamandridae','Salamandra','Salamandra salamandra'),
    ('Animalia','Chordata','Reptilia','Squamata','Lacertidae','Lacerta','Lacerta agilis'),
    ('Animalia','Chordata','Reptilia','Squamata','Lacertidae','Podarcis','Podarcis muralis'),
    ('Animalia','Chordata','Reptilia','Squamata','Colubridae','Natrix','Natrix natrix'),
    ('Animalia','Chordata','Actinopterygii','Cypriniformes','Cyprinidae','Cyprinus','Cyprinus carpio'),
    ('Animalia','Chordata','Actinopterygii','Salmoniformes','Salmonidae','Salmo','Salmo trutta'),
    ('Animalia','Arthropoda','Insecta','Lepidoptera','Nymphalidae','Aglais','Aglais urticae'),
    ('Animalia','Arthropoda','Insecta','Lepidoptera','Nymphalidae','Vanessa','Vanessa atalanta'),
    ('Animalia','Arthropoda','Insecta','Lepidoptera','Nymphalidae','Inachis','Inachis io'),
    ('Animalia','Arthropoda','Insecta','Lepidoptera','Papilionidae','Papilio','Papilio machaon'),
    ('Animalia','Arthropoda','Insecta','Coleoptera','Coccinellidae','Coccinella','Coccinella septempunctata'),
    ('Animalia','Arthropoda','Insecta','Coleoptera','Lucanidae','Lucanus','Lucanus cervus'),
    ('Animalia','Arthropoda','Insecta','Coleoptera','Carabidae','Carabus','Carabus auratus'),
    ('Animalia','Arthropoda','Insecta','Hymenoptera','Apidae','Apis','Apis mellifera'),
    ('Animalia','Arthropoda','Insecta','Hymenoptera','Apidae','Bombus','Bombus terrestris'),
    ('Animalia','Arthropoda','Insecta','Odonata','Libellulidae','Libellula','Libellula depressa'),
    ('Animalia','Arthropoda','Arachnida','Araneae','Araneidae','Araneus','Araneus diadematus'),
    ('Animalia','Mollusca','Gastropoda','Stylommatophora','Helicidae','Helix','Helix pomatia'),
    ('Animalia','Mollusca','Gastropoda','Stylommatophora','Helicidae','Cornu','Cornu aspersum'),
    ('Animalia','Annelida','Clitellata','Haplotaxida','Lumbricidae','Lumbricus','Lumbricus terrestris');

    CREATE TEMP TABLE tax_plant(kingdom text,phylum text,class text,taxon_order text,family text,genus text,species text) ON COMMIT DROP;
    INSERT INTO tax_plant VALUES
    ('Plantae','Tracheophyta','Magnoliopsida','Fagales','Fagaceae','Quercus','Quercus robur'),
    ('Plantae','Tracheophyta','Magnoliopsida','Fagales','Fagaceae','Quercus','Quercus petraea'),
    ('Plantae','Tracheophyta','Magnoliopsida','Fagales','Fagaceae','Quercus','Quercus ilex'),
    ('Plantae','Tracheophyta','Magnoliopsida','Fagales','Fagaceae','Fagus','Fagus sylvatica'),
    ('Plantae','Tracheophyta','Magnoliopsida','Fagales','Fagaceae','Castanea','Castanea sativa'),
    ('Plantae','Tracheophyta','Magnoliopsida','Fagales','Betulaceae','Betula','Betula pendula'),
    ('Plantae','Tracheophyta','Magnoliopsida','Fagales','Betulaceae','Betula','Betula pubescens'),
    ('Plantae','Tracheophyta','Magnoliopsida','Fagales','Betulaceae','Alnus','Alnus glutinosa'),
    ('Plantae','Tracheophyta','Magnoliopsida','Rosales','Rosaceae','Rosa','Rosa canina'),
    ('Plantae','Tracheophyta','Magnoliopsida','Rosales','Rosaceae','Prunus','Prunus avium'),
    ('Plantae','Tracheophyta','Magnoliopsida','Rosales','Rosaceae','Prunus','Prunus spinosa'),
    ('Plantae','Tracheophyta','Magnoliopsida','Rosales','Rosaceae','Malus','Malus domestica'),
    ('Plantae','Tracheophyta','Magnoliopsida','Rosales','Rosaceae','Crataegus','Crataegus monogyna'),
    ('Plantae','Tracheophyta','Magnoliopsida','Lamiales','Lamiaceae','Thymus','Thymus vulgaris'),
    ('Plantae','Tracheophyta','Magnoliopsida','Lamiales','Lamiaceae','Salvia','Salvia officinalis'),
    ('Plantae','Tracheophyta','Magnoliopsida','Lamiales','Lamiaceae','Mentha','Mentha aquatica'),
    ('Plantae','Tracheophyta','Magnoliopsida','Lamiales','Oleaceae','Fraxinus','Fraxinus excelsior'),
    ('Plantae','Tracheophyta','Magnoliopsida','Asterales','Asteraceae','Bellis','Bellis perennis'),
    ('Plantae','Tracheophyta','Magnoliopsida','Asterales','Asteraceae','Taraxacum','Taraxacum officinale'),
    ('Plantae','Tracheophyta','Magnoliopsida','Asterales','Asteraceae','Centaurea','Centaurea jacea'),
    ('Plantae','Tracheophyta','Magnoliopsida','Fabales','Fabaceae','Trifolium','Trifolium pratense'),
    ('Plantae','Tracheophyta','Magnoliopsida','Fabales','Fabaceae','Robinia','Robinia pseudoacacia'),
    ('Plantae','Tracheophyta','Magnoliopsida','Ranunculales','Ranunculaceae','Ranunculus','Ranunculus acris'),
    ('Plantae','Tracheophyta','Magnoliopsida','Brassicales','Brassicaceae','Brassica','Brassica napus'),
    ('Plantae','Tracheophyta','Liliopsida','Poales','Poaceae','Triticum','Triticum aestivum'),
    ('Plantae','Tracheophyta','Liliopsida','Poales','Poaceae','Festuca','Festuca rubra'),
    ('Plantae','Tracheophyta','Liliopsida','Asparagales','Orchidaceae','Orchis','Orchis militaris'),
    ('Plantae','Tracheophyta','Liliopsida','Liliales','Liliaceae','Lilium','Lilium martagon'),
    ('Plantae','Tracheophyta','Pinopsida','Pinales','Pinaceae','Pinus','Pinus sylvestris'),
    ('Plantae','Tracheophyta','Pinopsida','Pinales','Pinaceae','Pinus','Pinus cembra'),
    ('Plantae','Tracheophyta','Pinopsida','Pinales','Pinaceae','Picea','Picea abies'),
    ('Plantae','Tracheophyta','Pinopsida','Pinales','Pinaceae','Abies','Abies alba'),
    ('Plantae','Tracheophyta','Pinopsida','Pinales','Cupressaceae','Juniperus','Juniperus communis'),
    ('Plantae','Tracheophyta','Polypodiopsida','Polypodiales','Dryopteridaceae','Dryopteris','Dryopteris filix-mas');

    CREATE TEMP TABLE tax_foss(kingdom text,phylum text,class text,taxon_order text,family text,genus text,species text,period text) ON COMMIT DROP;
    INSERT INTO tax_foss VALUES
    ('Animalia','Arthropoda','Trilobita','Redlichiida','Paradoxididae','Paradoxides','Paradoxides paradoxissimus','Cambrian'),
    ('Animalia','Arthropoda','Trilobita','Redlichiida','Paradoxididae','Paradoxides','Paradoxides davidis','Cambrian'),
    ('Animalia','Arthropoda','Trilobita','Phacopida','Calymenidae','Calymene','Calymene blumenbachii','Silurian'),
    ('Animalia','Arthropoda','Trilobita','Phacopida','Phacopidae','Phacops','Phacops rana','Devonian'),
    ('Animalia','Arthropoda','Trilobita','Asaphida','Asaphidae','Asaphus','Asaphus expansus','Ordovician'),
    ('Animalia','Mollusca','Cephalopoda','Ammonitida','Dactylioceratidae','Dactylioceras','Dactylioceras commune','Jurassic'),
    ('Animalia','Mollusca','Cephalopoda','Ammonitida','Hildoceratidae','Hildoceras','Hildoceras bifrons','Jurassic'),
    ('Animalia','Mollusca','Cephalopoda','Ammonitida','Perisphinctidae','Perisphinctes','Perisphinctes plicatilis','Jurassic'),
    ('Animalia','Mollusca','Cephalopoda','Belemnitida','Belemnitidae','Belemnites','Belemnites paxillosus','Jurassic'),
    ('Animalia','Mollusca','Cephalopoda','Ceratitida','Ceratitidae','Ceratites','Ceratites nodosus','Triassic'),
    ('Animalia','Mollusca','Bivalvia','Ostreida','Gryphaeidae','Gryphaea','Gryphaea arcuata','Jurassic'),
    ('Animalia','Brachiopoda','Rhynchonellata','Spiriferida','Spiriferidae','Spirifer','Spirifer striatus','Carboniferous'),
    ('Animalia','Echinodermata','Crinoidea','Encrinida','Encrinidae','Encrinus','Encrinus liliiformis','Triassic'),
    ('Animalia','Cnidaria','Anthozoa','Stauriida','Disphyllidae','Hexagonaria','Hexagonaria percarinata','Devonian'),
    ('Animalia','Chordata','Reptilia','Saurischia','Tyrannosauridae','Tyrannosaurus','Tyrannosaurus rex','Cretaceous'),
    ('Animalia','Chordata','Reptilia','Saurischia','Diplodocidae','Diplodocus','Diplodocus carnegii','Jurassic'),
    ('Animalia','Chordata','Reptilia','Ornithischia','Iguanodontidae','Iguanodon','Iguanodon bernissartensis','Cretaceous'),
    ('Animalia','Chordata','Reptilia','Ornithischia','Stegosauridae','Stegosaurus','Stegosaurus stenops','Jurassic'),
    ('Animalia','Chordata','Mammalia','Proboscidea','Elephantidae','Mammuthus','Mammuthus primigenius','Quaternary'),
    ('Animalia','Chordata','Mammalia','Carnivora','Felidae','Smilodon','Smilodon fatalis','Neogene'),
    ('Plantae','Tracheophyta','Lycopodiopsida','Lepidodendrales','Lepidodendraceae','Lepidodendron','Lepidodendron aculeatum','Carboniferous');

    CREATE TEMP TABLE tax_min(mineral_class text,species text,crystal_system text,mohs text,formula text) ON COMMIT DROP;
    INSERT INTO tax_min VALUES
    ('native elements','Gold','cubic','2.5','Au'),
    ('native elements','Copper','cubic','2.5','Cu'),
    ('native elements','Silver','cubic','2.5','Ag'),
    ('native elements','Sulfur','orthorhombic','2','S'),
    ('native elements','Graphite','hexagonal','1.5','C'),
    ('native elements','Diamond','cubic','10','C'),
    ('sulfides','Pyrite','cubic','6','FeS2'),
    ('sulfides','Galena','cubic','2.5','PbS'),
    ('sulfides','Sphalerite','cubic','3.5','ZnS'),
    ('sulfides','Chalcopyrite','tetragonal','3.5','CuFeS2'),
    ('sulfides','Cinnabar','trigonal','2','HgS'),
    ('sulfides','Stibnite','orthorhombic','2','Sb2S3'),
    ('oxides','Hematite','trigonal','6','Fe2O3'),
    ('oxides','Magnetite','cubic','6','Fe3O4'),
    ('oxides','Corundum','trigonal','9','Al2O3'),
    ('oxides','Rutile','tetragonal','6','TiO2'),
    ('oxides','Cassiterite','tetragonal','6.5','SnO2'),
    ('oxides','Spinel','cubic','8','MgAl2O4'),
    ('halides','Halite','cubic','2.5','NaCl'),
    ('halides','Fluorite','cubic','4','CaF2'),
    ('halides','Sylvite','cubic','2','KCl'),
    ('carbonates','Calcite','trigonal','3','CaCO3'),
    ('carbonates','Dolomite','trigonal','3.5','CaMg(CO3)2'),
    ('carbonates','Aragonite','orthorhombic','3.5','CaCO3'),
    ('carbonates','Malachite','monoclinic','3.5','Cu2CO3(OH)2'),
    ('carbonates','Azurite','monoclinic','3.5','Cu3(CO3)2(OH)2'),
    ('sulfates','Gypsum','monoclinic','2','CaSO4(H2O)2'),
    ('sulfates','Barite','orthorhombic','3','BaSO4'),
    ('sulfates','Anhydrite','orthorhombic','3.5','CaSO4'),
    ('sulfates','Celestine','orthorhombic','3.5','SrSO4'),
    ('phosphates','Apatite','hexagonal','5','Ca5(PO4)3F'),
    ('phosphates','Turquoise','triclinic','5','CuAl6(PO4)4(OH)8'),
    ('phosphates','Vivianite','monoclinic','1.5','Fe3(PO4)2(H2O)8'),
    ('silicates','Quartz','trigonal','7','SiO2'),
    ('silicates','Orthoclase','monoclinic','6','KAlSi3O8'),
    ('silicates','Albite','triclinic','6.5','NaAlSi3O8'),
    ('silicates','Muscovite','monoclinic','2.5','KAl2(AlSi3O10)(OH)2'),
    ('silicates','Biotite','monoclinic','2.5','K(Mg,Fe)3AlSi3O10(OH)2'),
    ('silicates','Olivine','orthorhombic','7','(Mg,Fe)2SiO4'),
    ('silicates','Almandine','cubic','7.5','Fe3Al2(SiO4)3'),
    ('silicates','Beryl','hexagonal','7.5','Be3Al2Si6O18'),
    ('silicates','Topaz','orthorhombic','8','Al2SiO4(F,OH)2'),
    ('silicates','Tourmaline','trigonal','7.5','Na(Mg,Fe)3Al6(BO3)3Si6O18(OH)4'),
    ('silicates','Talc','monoclinic','1','Mg3Si4O10(OH)2'),
    ('silicates','Epidote','monoclinic','6.5','Ca2Al2(FeAl)(SiO4)(Si2O7)O(OH)');

    ------------------------------------------------------------------
    -- generic hierarchy builder: rank by rank, parent looked up by name
    ------------------------------------------------------------------
    CREATE TEMP TABLE tmp_nodes(list bigint, rank text, name text, ili_id bigint, item_id bigint) ON COMMIT DROP;

    FOR cfg IN
        SELECT * FROM (VALUES
            (L_animalia,'tax_anim',ARRAY['kingdom','phylum','class','taxon_order','family','genus','species']),
            (L_plants,  'tax_plant',ARRAY['kingdom','phylum','class','taxon_order','family','genus','species']),
            (L_paleo,   'tax_foss', ARRAY['kingdom','phylum','class','taxon_order','family','genus','species']),
            (L_min,     'tax_min',  ARRAY['mineral_class','species'])
        ) AS c(list_id, tbl, ranks)
    LOOP
        ranks := cfg.ranks;
        FOR i IN 1 .. array_length(ranks,1) LOOP
            col := ranks[i];
            IF i = 1 THEN pcol_expr := 'NULL::text';
            ELSE pcol_expr := format('t.%I', ranks[i-1]); END IF;

            EXECUTE format($f$
                WITH d AS (
                    SELECT DISTINCT t.%1$I AS name, %2$s AS pname
                    FROM %3$I t WHERE t.%1$I IS NOT NULL
                ),
                names AS (SELECT DISTINCT name FROM d),
                ii AS (
                    INSERT INTO dbnext.item(language, data, name)
                    SELECT 'la','{}'::jsonb, name FROM names
                    RETURNING id, name
                ),
                ni AS (
                    INSERT INTO dbnext.item_list_item(id_item_list, id_item, id_parent)
                    SELECT $1, ii.id, p.ili_id
                    FROM d
                    JOIN ii ON ii.name = d.name
                    LEFT JOIN tmp_nodes p ON p.list = $1 AND p.name = d.pname
                    RETURNING id, id_item
                )
                INSERT INTO tmp_nodes(list, rank, name, ili_id, item_id)
                SELECT $1, %4$L, ii.name, ni.id, ni.id_item
                FROM ni JOIN ii ON ii.id = ni.id_item
            $f$, col, pcol_expr, cfg.tbl, col)
            USING cfg.list_id;
        END LOOP;
    END LOOP;

    -- attach reference attributes to the species-level items
    UPDATE dbnext.item it
       SET data = jsonb_build_object('period', t.period)
      FROM tmp_nodes n JOIN tax_foss t ON t.species = n.name
     WHERE n.list = L_paleo AND n.rank = 'species' AND it.id = n.item_id;

    UPDATE dbnext.item it
       SET data = jsonb_build_object('crystal_system',t.crystal_system,
                                     'mohs_hardness',t.mohs,
                                     'chemical_formula',t.formula,
                                     'mineral_class',t.mineral_class)
      FROM tmp_nodes n JOIN tax_min t ON t.species = n.name
     WHERE n.list = L_min AND n.rank = 'species' AND it.id = n.item_id;

    ------------------------------------------------------------------
    -- species pools used by record generation
    ------------------------------------------------------------------
    CREATE TEMP TABLE pool_ls ON COMMIT DROP AS
        SELECT ili_id FROM tmp_nodes WHERE list IN (L_animalia, L_plants) AND rank='species';
    CREATE TEMP TABLE pool_foss ON COMMIT DROP AS
        SELECT n.ili_id, it.data->>'period' AS period
        FROM tmp_nodes n JOIN dbnext.item it ON it.id = n.item_id
        WHERE n.list = L_paleo AND n.rank='species';
    CREATE TEMP TABLE pool_min ON COMMIT DROP AS
        SELECT n.ili_id, it.data->>'crystal_system' AS crystal_system,
               it.data->>'mohs_hardness' AS mohs, it.data->>'chemical_formula' AS formula,
               it.data->>'mineral_class' AS mineral_class
        FROM tmp_nodes n JOIN dbnext.item it ON it.id = n.item_id
        WHERE n.list = L_min AND n.rank='species';

    ------------------------------------------------------------------
    -- 10000 OBSERVATIONS (project 7)
    ------------------------------------------------------------------
    -- NB: pick the species by random ARRAY INDEX evaluated per generated row.
    -- An uncorrelated "LATERAL (... ORDER BY random() LIMIT 1)" is evaluated
    -- once by the planner and would assign the SAME species to all 10000 rows.
    CREATE TEMP TABLE g_obs ON COMMIT DROP AS
    WITH p AS (SELECT array_agg(ili_id) a_ili, count(*)::int c FROM pool_ls)
    SELECT nextval('dbnext.project_record_id_seq') AS rec_id,
           p.a_ili[s.idx] AS ili_id,
           (timestamptz '2019-01-01' + (random()*2000) * interval '1 day') AS d_start,
           (-10 + random()*40)::float8 AS lon,
           (35 + random()*25)::float8  AS lat,
           (1 + floor(random()*20))::int AS abundance,
           (ARRAY['egg','larva','juvenile','adult'])[1+floor(random()*4)] AS life_stage,
           (ARRAY['male','female','unknown'])[1+floor(random()*3)] AS sex,
           (CASE WHEN random()<0.5 THEN u_a ELSE u_b END) AS det_user,
           s.n
    FROM p, LATERAL (SELECT n, 1+floor(random()*p.c)::int AS idx
                     FROM generate_series(1,10000) n) s;

    INSERT INTO dbnext.project_record(id, data, date_start, created_by)
        SELECT rec_id, jsonb_build_object('abundance',abundance,'life_stage',life_stage,'sex',sex), d_start, v_admin FROM g_obs;
    INSERT INTO dbnext.project_record_project(id_project_record, id_project) SELECT rec_id, 7 FROM g_obs;
    INSERT INTO dbnext.project_record_determination(id_project_record, id_item_list_item, preferred, determined_by, id_determination_method, determination_date)
        SELECT rec_id, ili_id, true, det_user, k_morph, d_start::date FROM g_obs;
    INSERT INTO dbnext.project_record_geometry(id_record, geom)
        SELECT rec_id, public.ST_SetSRID(public.ST_MakePoint(lon,lat),4326) FROM g_obs;
    INSERT INTO dbnext.project_record_keyword(id_project_record, id_keyword) SELECT rec_id, k_dom_obs FROM g_obs;
    INSERT INTO dbnext.project_record_keyword(id_project_record, id_keyword)
        SELECT g.rec_id, k.a[1+floor(random()*k.c)::int]
        FROM g_obs g, (SELECT array_agg(id) a, count(*)::int c
                       FROM dbnext.keyword WHERE id_parent=k_conserv_p) k;
    INSERT INTO dbnext.project_record_identifier(id_project_record, id_keyword, value)
        SELECT rec_id, k_catalog, 'LSO-'||rec_id FROM g_obs;
    INSERT INTO dbnext.project_record_user(id_user, id_project_record) SELECT det_user, rec_id FROM g_obs;
    -- role keyword: observers on observation records
    INSERT INTO dbnext.project_record_user_keyword(id_project_record_user, id_keyword)
        SELECT pru.id, (SELECT id FROM dbnext.keyword WHERE name='observer'
                        AND id_parent=(SELECT id FROM dbnext.keyword WHERE name='User Role' AND id_parent IS NULL))
        FROM dbnext.project_record_user pru
        JOIN g_obs g ON g.rec_id = pru.id_project_record AND g.det_user = pru.id_user;
    -- sample of external GBIF identifiers
    INSERT INTO dbnext.external_identifier(source, identifier, url, description)
        SELECT 'GBIF','OCC-'||rec_id,'https://www.gbif.org/occurrence/'||rec_id,'bulk demo occurrence' FROM g_obs WHERE n % 50 = 0;
    INSERT INTO dbnext.external_identifier_project_record(id_external_identifier, id_project_record)
        SELECT e.id, g.rec_id FROM g_obs g JOIN dbnext.external_identifier e ON e.identifier='OCC-'||g.rec_id WHERE g.n % 50 = 0;

    ------------------------------------------------------------------
    -- 10000 LIFE-SCIENCE COLLECTIONS (project 8)
    ------------------------------------------------------------------
    CREATE TEMP TABLE g_coll ON COMMIT DROP AS
    WITH p AS (SELECT array_agg(ili_id) a_ili, count(*)::int c FROM pool_ls)
    SELECT nextval('dbnext.project_record_id_seq') AS rec_id,
           p.a_ili[s.idx] AS ili_id,
           (timestamptz '1900-01-01' + (random()*44000) * interval '1 day') AS d_day,
           (-10 + random()*40)::float8 AS lon,
           (35 + random()*25)::float8  AS lat,
           (CASE WHEN random()<0.5 THEN u_a ELSE u_b END) AS det_user,
           s.n
    FROM p, LATERAL (SELECT n, 1+floor(random()*p.c)::int AS idx
                     FROM generate_series(1,10000) n) s;

    INSERT INTO dbnext.project_record(id, data, date_start, date_end, created_by)
        SELECT rec_id, '{}'::jsonb, d_day, d_day, v_admin FROM g_coll;
    INSERT INTO dbnext.project_record_project(id_project_record, id_project) SELECT rec_id, 8 FROM g_coll;
    INSERT INTO dbnext.project_record_determination(id_project_record, id_item_list_item, preferred, determined_by, id_determination_method)
        SELECT rec_id, ili_id, true, det_user, k_morph FROM g_coll;
    INSERT INTO dbnext.project_record_geometry(id_record, geom)
        SELECT rec_id, public.ST_SetSRID(public.ST_MakePoint(lon,lat),4326) FROM g_coll;
    INSERT INTO dbnext.project_record_keyword(id_project_record, id_keyword) SELECT rec_id, k_dom_coll FROM g_coll;
    INSERT INTO dbnext.project_record_keyword(id_project_record, id_keyword)
        SELECT g.rec_id, k.a[1+floor(random()*k.c)::int]
        FROM g_coll g, (SELECT array_agg(id) a, count(*)::int c
                        FROM dbnext.keyword WHERE id_parent=k_preserv_p) k;
    INSERT INTO dbnext.project_record_identifier(id_project_record, id_keyword, value)
        SELECT rec_id, k_catalog, 'LSC-'||rec_id FROM g_coll;
    INSERT INTO dbnext.project_record_user(id_user, id_project_record) SELECT det_user, rec_id FROM g_coll;
    -- role keyword: collectors on collection records
    INSERT INTO dbnext.project_record_user_keyword(id_project_record_user, id_keyword)
        SELECT pru.id, (SELECT id FROM dbnext.keyword WHERE name='collector'
                        AND id_parent=(SELECT id FROM dbnext.keyword WHERE name='User Role' AND id_parent IS NULL))
        FROM dbnext.project_record_user pru
        JOIN g_coll g ON g.rec_id = pru.id_project_record AND g.det_user = pru.id_user;

    ------------------------------------------------------------------
    -- 10000 PALEONTOLOGY (project 9)
    ------------------------------------------------------------------
    CREATE TEMP TABLE g_pal ON COMMIT DROP AS
    WITH p AS (SELECT array_agg(ili_id) a_ili, array_agg(period) a_per, count(*)::int c FROM pool_foss)
    SELECT nextval('dbnext.project_record_id_seq') AS rec_id,
           p.a_ili[s.idx] AS ili_id, p.a_per[s.idx] AS period,
           (-170 + random()*340)::float8 AS lon,
           (-55 + random()*125)::float8  AS lat,
           (ARRAY['Alum Shale','Whitby Mudstone','Wenlock Limestone','Solnhofen Limestone','Hell Creek','Morrison'])[1+floor(random()*6)] AS formation,
           s.n
    FROM p, LATERAL (SELECT n, 1+floor(random()*p.c)::int AS idx
                     FROM generate_series(1,10000) n) s;

    INSERT INTO dbnext.project_record(id, data, created_by)
        SELECT rec_id, jsonb_build_object('period',period,'formation',formation), v_admin FROM g_pal;
    INSERT INTO dbnext.project_record_project(id_project_record, id_project) SELECT rec_id, 9 FROM g_pal;
    INSERT INTO dbnext.project_record_determination(id_project_record, id_item_list_item, preferred, determined_by, id_determination_method)
        SELECT rec_id, ili_id, true, u_b, k_morph FROM g_pal;
    INSERT INTO dbnext.project_record_geometry(id_record, geom)
        SELECT rec_id, public.ST_SetSRID(public.ST_MakePoint(lon,lat),4326) FROM g_pal;
    INSERT INTO dbnext.project_record_keyword(id_project_record, id_keyword) SELECT rec_id, k_dom_paleo FROM g_pal;
    INSERT INTO dbnext.project_record_keyword(id_project_record, id_keyword)
        SELECT g.rec_id, k.id FROM g_pal g JOIN dbnext.keyword k ON k.name = g.period AND k.id_parent = k_period_p;
    INSERT INTO dbnext.project_record_identifier(id_project_record, id_keyword, value)
        SELECT rec_id, k_accession, 'PALB-'||rec_id FROM g_pal;

    ------------------------------------------------------------------
    -- 10000 MINERALOGY (project 10)
    ------------------------------------------------------------------
    CREATE TEMP TABLE g_min ON COMMIT DROP AS
    WITH p AS (SELECT array_agg(ili_id) a_ili, array_agg(crystal_system) a_cs,
                      array_agg(mohs) a_mohs, array_agg(formula) a_f,
                      array_agg(mineral_class) a_mc, count(*)::int c FROM pool_min)
    SELECT nextval('dbnext.project_record_id_seq') AS rec_id,
           p.a_ili[s.idx] AS ili_id, p.a_cs[s.idx] AS crystal_system,
           p.a_mohs[s.idx] AS mohs, p.a_f[s.idx] AS formula, p.a_mc[s.idx] AS mineral_class,
           (-170 + random()*340)::float8 AS lon,
           (-55 + random()*125)::float8  AS lat,
           s.n
    FROM p, LATERAL (SELECT n, 1+floor(random()*p.c)::int AS idx
                     FROM generate_series(1,10000) n) s;

    INSERT INTO dbnext.project_record(id, data, created_by)
        SELECT rec_id, jsonb_build_object('crystal_system',crystal_system,'mohs_hardness',mohs,'chemical_formula',formula), v_admin FROM g_min;
    INSERT INTO dbnext.project_record_project(id_project_record, id_project) SELECT rec_id, 10 FROM g_min;
    INSERT INTO dbnext.project_record_determination(id_project_record, id_item_list_item, preferred, determined_by, id_determination_method)
        SELECT rec_id, ili_id, true, u_a, k_xrd FROM g_min;
    INSERT INTO dbnext.project_record_geometry(id_record, geom)
        SELECT rec_id, public.ST_SetSRID(public.ST_MakePoint(lon,lat),4326) FROM g_min;
    INSERT INTO dbnext.project_record_keyword(id_project_record, id_keyword) SELECT rec_id, k_dom_min FROM g_min;
    INSERT INTO dbnext.project_record_keyword(id_project_record, id_keyword)
        SELECT g.rec_id, k.id FROM g_min g JOIN dbnext.keyword k ON k.name = g.mineral_class AND k.id_parent = k_minclass_p;
    INSERT INTO dbnext.project_record_identifier(id_project_record, id_keyword, value)
        SELECT rec_id, k_catalog, 'MINB-'||rec_id FROM g_min;

    -- taxon lineage (branch / rank / classification) is added afterwards by
    -- sql/seed_taxon_branch.sql — run it as the last seed step.

    RAISE NOTICE 'bulk seed loaded: % records added across projects 7-10',
        (SELECT count(*) FROM dbnext.project_record_identifier
         WHERE value LIKE 'LSO-%' OR value LIKE 'LSC-%' OR value LIKE 'PALB-%' OR value LIKE 'MINB-%');
END
$bulk$;

COMMIT;
