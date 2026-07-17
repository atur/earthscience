--
-- seed_test_data.sql — realistic museum-of-natural-history demo data
--
-- Targets the LIVE database (schema `dbnext`). Populates the four existing
-- domain projects (7 Life Science Observations, 8 Life Science Collections,
-- 9 Paleontology Collections, 10 Mineralogy Collections) with a realistic,
-- persistent dataset and exercises every distinctive schema feature:
-- PostGIS geometry, temporal tstzrange, jsonb custom fields, pg_trgm name
-- search, hierarchical taxonomies with synonymy, determinations, typed
-- keyword classification, record relationships and the deferred integrity
-- triggers.
--
-- Classification is keyword-driven: every record/taxonomy/project is tagged
-- with its Domain keyword (40 -> 42..45) and many domain-specific keyword
-- hierarchies (geological period, mineral class, conservation status, type
-- status, identifier type, determination method, relationship type, ...).
--
-- IDEMPOTENT: guarded by the root keyword `demo-seed`. Re-running is a no-op
-- (RAISE NOTICE, no duplicate rows). Use seed_teardown.sql to remove it.
--
-- The whole load runs in ONE transaction so the deferred
-- trg_project_record_requires_project (every project_record needs >=1
-- project_record_project by COMMIT) is satisfied. Run in pgAdmin/psql as-is.
--

BEGIN;

DO $seed$
DECLARE
    v_admin        bigint := 13;   -- existing user "Armand Turpel"

    -- existing domain keywords (Domain root 40)
    k_dom_obs      bigint := 42;   -- Life Science Observations
    k_dom_coll     bigint := 43;   -- Life Science Collections
    k_dom_paleo    bigint := 44;   -- Paleontology Collections
    k_dom_min      bigint := 45;   -- Mineralogy Collections

    -- existing domain projects
    p_obs          bigint := 7;
    p_coll         bigint := 8;
    p_paleo        bigint := 9;
    p_min          bigint := 10;

    -- data_groups
    dg_paleo       bigint;
    dg_mineral     bigint;
    dg_biodiv      bigint;
    dg_kw          bigint;   -- metadata group for keywords
    dg_list        bigint;   -- item_list custom fields
    dg_item        bigint;   -- item-within-list custom fields
    dg_media       bigint;

    -- data_definitions whose predefined values we set
    dd_period      bigint;
    dd_crystal     bigint;
    dd_lifestage   bigint;
    dd_sex         bigint;

    -- keyword group parents
    k_idtype       bigint;
    k_detmethod    bigint;
    k_reltype      bigint;
    k_role         bigint;
    k_preserv      bigint;
    k_conserv      bigint;
    k_typestatus   bigint;
    k_period       bigint;
    k_minclass     bigint;
    k_sampletype   bigint;

    -- frequently used leaf keywords
    k_catalog      bigint;
    k_accession    bigint;
    k_barcode      bigint;
    k_morph        bigint;
    k_molecular    bigint;
    k_xrd          bigint;
    k_dupof        bigint;
    k_derived      bigint;
    k_collector    bigint;
    k_observer     bigint;
    k_determiner   bigint;

    -- users
    u_maria        bigint;
    u_jean         bigint;

    -- item_lists
    il_birds       bigint;
    il_plants      bigint;
    il_fossils     bigint;
    il_minerals    bigint;

    -- species-level item_list_item ids used by determinations
    ili_parus      bigint;   -- Parus major
    ili_cyan       bigint;   -- Cyanistes caeruleus
    ili_erith      bigint;   -- Erithacus rubecula
    ili_qrobur     bigint;   -- Quercus robur
    ili_qpetraea   bigint;   -- Quercus petraea
    ili_fagus      bigint;   -- Fagus sylvatica
    ili_paradox    bigint;   -- Paradoxides paradoxissimus
    ili_dactyl     bigint;   -- Dactylioceras commune
    ili_calymene   bigint;   -- Calymene blumenbachii
    ili_quartz     bigint;   -- Quartz
    ili_pyrite     bigint;   -- Pyrite
    ili_calcite    bigint;   -- Calcite
    ili_fluorite   bigint;   -- Fluorite
    ili_galena     bigint;   -- Galena

    -- item ids used for media / external-identifier links
    it_qrobur      bigint;
    it_parus       bigint;
    it_quartz      bigint;

    -- project_records
    r_o1 bigint; r_o2 bigint; r_o3 bigint; r_o4 bigint;
    r_c1 bigint; r_c2 bigint; r_c3 bigint; r_c4 bigint;
    r_p1 bigint; r_p2 bigint; r_p3 bigint; r_plot bigint; r_pthin bigint;
    r_m1 bigint; r_m2 bigint; r_m3 bigint; r_m4 bigint; r_mlot bigint; r_mpol bigint;

    -- determinations whose keyword we tag
    det_c1 bigint;

    -- helpers
    v_pru bigint;
    v_med bigint;
    v_ext bigint;
BEGIN
    ------------------------------------------------------------------
    -- 0. idempotency guard
    ------------------------------------------------------------------
    IF EXISTS (SELECT 1 FROM dbnext.keyword
               WHERE name = 'demo-seed' AND id_parent IS NULL) THEN
        RAISE NOTICE 'demo seed already present — skipping (run seed_teardown.sql to reset)';
        RETURN;
    END IF;

    ------------------------------------------------------------------
    -- 1. data_groups (custom-field schemas)
    ------------------------------------------------------------------
    INSERT INTO dbnext.data_group(name, description) VALUES
        ('demo: paleo record fields',        'custom fields for fossil records'),
        ('demo: mineral record fields',      'custom fields for mineral records'),
        ('demo: biodiversity record fields', 'custom fields for observation/collection records'),
        ('demo: keyword metadata',           'metadata group for demo keywords'),
        ('demo: taxonomy list fields',       'custom fields on item_list'),
        ('demo: taxon item fields',          'custom fields on items within a list'),
        ('demo: media fields',               'custom fields on media');

    SELECT id INTO dg_paleo   FROM dbnext.data_group WHERE name='demo: paleo record fields';
    SELECT id INTO dg_mineral FROM dbnext.data_group WHERE name='demo: mineral record fields';
    SELECT id INTO dg_biodiv  FROM dbnext.data_group WHERE name='demo: biodiversity record fields';
    SELECT id INTO dg_kw      FROM dbnext.data_group WHERE name='demo: keyword metadata';
    SELECT id INTO dg_list    FROM dbnext.data_group WHERE name='demo: taxonomy list fields';
    SELECT id INTO dg_item    FROM dbnext.data_group WHERE name='demo: taxon item fields';
    SELECT id INTO dg_media   FROM dbnext.data_group WHERE name='demo: media fields';

    ------------------------------------------------------------------
    -- 2. data_definitions + predefined values
    ------------------------------------------------------------------
    INSERT INTO dbnext.data_definition(id_group, name, type, description, rank) VALUES
        (dg_paleo,   'period',          'string', 'geological period',  1),
        (dg_paleo,   'formation',       'string', 'lithostratigraphic unit', 2),
        (dg_paleo,   'stage',           'string', 'chronostratigraphic stage', 3),
        (dg_mineral, 'crystal_system',  'string', 'crystal system',     1),
        (dg_mineral, 'mohs_hardness',   'string', 'Mohs hardness',      2),
        (dg_mineral, 'chemical_formula','string', 'chemical formula',   3),
        (dg_biodiv,  'abundance',       'int',    'individuals counted',1),
        (dg_biodiv,  'life_stage',      'string', 'life stage',         2),
        (dg_biodiv,  'sex',             'string', 'sex',                3);

    SELECT id INTO dd_period    FROM dbnext.data_definition WHERE id_group=dg_paleo   AND name='period';
    SELECT id INTO dd_crystal   FROM dbnext.data_definition WHERE id_group=dg_mineral AND name='crystal_system';
    SELECT id INTO dd_lifestage FROM dbnext.data_definition WHERE id_group=dg_biodiv  AND name='life_stage';
    SELECT id INTO dd_sex       FROM dbnext.data_definition WHERE id_group=dg_biodiv  AND name='sex';

    UPDATE dbnext.data_definition SET predefined_values =
        ARRAY['Cambrian','Ordovician','Silurian','Devonian','Carboniferous','Permian','Triassic','Jurassic','Cretaceous','Paleogene','Neogene','Quaternary']
        WHERE id = dd_period;
    UPDATE dbnext.data_definition SET predefined_values =
        ARRAY['cubic','tetragonal','hexagonal','trigonal','orthorhombic','monoclinic','triclinic']
        WHERE id = dd_crystal;
    UPDATE dbnext.data_definition SET predefined_values =
        ARRAY['egg','larva','juvenile','adult']
        WHERE id = dd_lifestage;
    UPDATE dbnext.data_definition SET predefined_values =
        ARRAY['male','female','unknown']
        WHERE id = dd_sex;

    ------------------------------------------------------------------
    -- 3. keyword classification hierarchies (heavy use of keywords)
    ------------------------------------------------------------------
    -- sentinel
    INSERT INTO dbnext.keyword(name, description, id_data_group)
        VALUES ('demo-seed', 'marker: rows created by seed_test_data.sql', dg_kw);

    -- group parents
    INSERT INTO dbnext.keyword(name, description, id_data_group) VALUES
        ('Identifier Type',     'types of record identifiers', dg_kw),
        ('Determination Method','how a determination was made', dg_kw),
        ('Relationship Type',   'record-to-record relationship types', dg_kw),
        ('User Role',           'role of a person on a record', dg_kw),
        ('Preservation Method', 'how material is preserved', dg_kw),
        ('Conservation Status', 'IUCN-style conservation status', dg_kw),
        ('Specimen Type Status','nomenclatural type status', dg_kw),
        ('Geological Period',   'geological periods', dg_kw),
        ('Mineral Class',       'mineral chemical classes', dg_kw),
        ('Tissue/Sample Type',  'kind of physical material', dg_kw);

    SELECT id INTO k_idtype     FROM dbnext.keyword WHERE name='Identifier Type'      AND id_parent IS NULL;
    SELECT id INTO k_detmethod  FROM dbnext.keyword WHERE name='Determination Method' AND id_parent IS NULL;
    SELECT id INTO k_reltype    FROM dbnext.keyword WHERE name='Relationship Type'    AND id_parent IS NULL;
    SELECT id INTO k_role       FROM dbnext.keyword WHERE name='User Role'            AND id_parent IS NULL;
    SELECT id INTO k_preserv    FROM dbnext.keyword WHERE name='Preservation Method'  AND id_parent IS NULL;
    SELECT id INTO k_conserv    FROM dbnext.keyword WHERE name='Conservation Status'  AND id_parent IS NULL;
    SELECT id INTO k_typestatus FROM dbnext.keyword WHERE name='Specimen Type Status' AND id_parent IS NULL;
    SELECT id INTO k_period     FROM dbnext.keyword WHERE name='Geological Period'    AND id_parent IS NULL;
    SELECT id INTO k_minclass   FROM dbnext.keyword WHERE name='Mineral Class'        AND id_parent IS NULL;
    SELECT id INTO k_sampletype FROM dbnext.keyword WHERE name='Tissue/Sample Type'   AND id_parent IS NULL;

    -- children
    INSERT INTO dbnext.keyword(id_parent, name, description, id_data_group)
    SELECT k_idtype, x, 'identifier type', dg_kw FROM unnest(ARRAY[
        'Catalog Number','Accession Number','DNA Barcode','Field Number','Mindat ID','GBIF ID']) x;
    INSERT INTO dbnext.keyword(id_parent, name, description, id_data_group)
    SELECT k_detmethod, x, 'determination method', dg_kw FROM unnest(ARRAY[
        'morphological','molecular (DNA barcoding)','X-ray diffraction']) x;
    INSERT INTO dbnext.keyword(id_parent, name, description, id_data_group)
    SELECT k_reltype, x, 'relationship type', dg_kw FROM unnest(ARRAY[
        'duplicate of','same collection event','derived from','host of']) x;
    INSERT INTO dbnext.keyword(id_parent, name, description, id_data_group)
    SELECT k_role, x, 'user role', dg_kw FROM unnest(ARRAY[
        'collector','observer','determiner','preparator','curator']) x;
    INSERT INTO dbnext.keyword(id_parent, name, description, id_data_group)
    SELECT k_preserv, x, 'preservation method', dg_kw FROM unnest(ARRAY[
        'dried/herbarium','fluid (ethanol)','pinned','frozen tissue','cast/replica']) x;
    INSERT INTO dbnext.keyword(id_parent, name, description, id_data_group)
    SELECT k_conserv, x, 'conservation status', dg_kw FROM unnest(ARRAY[
        'least concern','near threatened','vulnerable','endangered']) x;
    INSERT INTO dbnext.keyword(id_parent, name, description, id_data_group)
    SELECT k_typestatus, x, 'type status', dg_kw FROM unnest(ARRAY[
        'holotype','paratype','syntype','type locality']) x;
    INSERT INTO dbnext.keyword(id_parent, name, description, id_data_group)
    SELECT k_period, x, 'geological period', dg_kw FROM unnest(ARRAY[
        'Cambrian','Ordovician','Silurian','Devonian','Carboniferous','Permian',
        'Triassic','Jurassic','Cretaceous','Paleogene','Neogene','Quaternary']) x;
    INSERT INTO dbnext.keyword(id_parent, name, description, id_data_group)
    SELECT k_minclass, x, 'mineral class', dg_kw FROM unnest(ARRAY[
        'native elements','sulfides','oxides','halides','carbonates','sulfates',
        'phosphates','silicates']) x;
    INSERT INTO dbnext.keyword(id_parent, name, description, id_data_group)
    SELECT k_sampletype, x, 'sample type', dg_kw FROM unnest(ARRAY[
        'whole organism','leaf','bone','shell','rock sample','thin section','DNA extract']) x;

    SELECT id INTO k_catalog    FROM dbnext.keyword WHERE name='Catalog Number'   AND id_parent=k_idtype;
    SELECT id INTO k_accession  FROM dbnext.keyword WHERE name='Accession Number' AND id_parent=k_idtype;
    SELECT id INTO k_barcode    FROM dbnext.keyword WHERE name='DNA Barcode'      AND id_parent=k_idtype;
    SELECT id INTO k_morph      FROM dbnext.keyword WHERE name='morphological'    AND id_parent=k_detmethod;
    SELECT id INTO k_molecular  FROM dbnext.keyword WHERE name='molecular (DNA barcoding)' AND id_parent=k_detmethod;
    SELECT id INTO k_xrd        FROM dbnext.keyword WHERE name='X-ray diffraction' AND id_parent=k_detmethod;
    SELECT id INTO k_dupof      FROM dbnext.keyword WHERE name='duplicate of'     AND id_parent=k_reltype;
    SELECT id INTO k_derived    FROM dbnext.keyword WHERE name='derived from'     AND id_parent=k_reltype;
    SELECT id INTO k_collector  FROM dbnext.keyword WHERE name='collector'        AND id_parent=k_role;
    SELECT id INTO k_observer   FROM dbnext.keyword WHERE name='observer'         AND id_parent=k_role;
    SELECT id INTO k_determiner FROM dbnext.keyword WHERE name='determiner'       AND id_parent=k_role;

    ------------------------------------------------------------------
    -- 4. users
    ------------------------------------------------------------------
    INSERT INTO dbnext.users(name, nickname, email, status, is_active)
        VALUES ('Maria Hofer', 'mhofer', 'maria.hofer@demo.museum', 'active', true)
        RETURNING id INTO u_maria;
    INSERT INTO dbnext.users(name, nickname, email, status, is_active)
        VALUES ('Jean Petit', 'jpetit', 'jean.petit@demo.museum', 'active', true)
        RETURNING id INTO u_jean;
    -- tag a user with a role keyword (users_keyword)
    INSERT INTO dbnext.users_keyword(id_user, id_keyword) VALUES
        (u_maria, k_collector), (u_jean, k_determiner),
        (v_admin, (SELECT id FROM dbnext.keyword WHERE name='curator' AND id_parent=k_role));

    ------------------------------------------------------------------
    -- 5. taxonomies: item_list / item / item_list_item (hierarchy + synonymy)
    ------------------------------------------------------------------
    INSERT INTO dbnext.item_list(name, description, data, item_list_id_data_group, item_list_item_id_data_group, created_by)
    VALUES
        ('Birds of Central Europe', 'demo bird checklist',   '{}'::jsonb, dg_list, dg_item, v_admin),
        ('Vascular Plants',         'demo plant taxonomy',   '{}'::jsonb, dg_list, dg_item, v_admin),
        ('Fossil Taxa',             'demo fossil taxonomy',  '{}'::jsonb, dg_list, dg_item, v_admin),
        ('Mineral Species',         'demo mineral species',  '{}'::jsonb, dg_list, dg_item, v_admin);

    SELECT id INTO il_birds    FROM dbnext.item_list WHERE name='Birds of Central Europe';
    SELECT id INTO il_plants   FROM dbnext.item_list WHERE name='Vascular Plants';
    SELECT id INTO il_fossils  FROM dbnext.item_list WHERE name='Fossil Taxa';
    SELECT id INTO il_minerals FROM dbnext.item_list WHERE name='Mineral Species';

    -- tag each taxonomy with its domain
    INSERT INTO dbnext.item_list_keyword(id_item_list, id_keyword) VALUES
        (il_birds, k_dom_obs), (il_plants, k_dom_coll),
        (il_fossils, k_dom_paleo), (il_minerals, k_dom_min);

    -- ---- BIRDS taxonomy (Aves > Passeriformes > family > genus > species) ----
    -- helper items (scientific names, language 'la')
    DECLARE
        a_aves bigint; a_pass bigint; a_parid bigint; a_musc bigint;
        a_parus_g bigint; a_cyan_g bigint; a_erith_g bigint;
        a_parus_s bigint; a_cyan_s bigint; a_erith_s bigint;
        a_cyan_syn bigint; -- old name Parus caeruleus
        ili_aves bigint; ili_pass bigint; ili_parid bigint; ili_musc bigint;
        ili_parus_g bigint; ili_cyan_g bigint; ili_erith_g bigint; ili_cyan_syn bigint;
        i_common bigint; ili_common bigint;
    BEGIN
        INSERT INTO dbnext.item(language, data, name) VALUES
            ('la','{}'::jsonb,'Aves'),('la','{}'::jsonb,'Passeriformes'),
            ('la','{}'::jsonb,'Paridae'),('la','{}'::jsonb,'Muscicapidae'),
            ('la','{}'::jsonb,'Parus'),('la','{}'::jsonb,'Cyanistes'),('la','{}'::jsonb,'Erithacus'),
            ('la','{}'::jsonb,'Parus major'),('la','{}'::jsonb,'Cyanistes caeruleus'),
            ('la','{}'::jsonb,'Erithacus rubecula'),('la','{}'::jsonb,'Parus caeruleus');
        SELECT id INTO a_aves    FROM dbnext.item WHERE name='Aves';
        SELECT id INTO a_pass    FROM dbnext.item WHERE name='Passeriformes';
        SELECT id INTO a_parid   FROM dbnext.item WHERE name='Paridae';
        SELECT id INTO a_musc    FROM dbnext.item WHERE name='Muscicapidae';
        SELECT id INTO a_parus_g FROM dbnext.item WHERE name='Parus';
        SELECT id INTO a_cyan_g  FROM dbnext.item WHERE name='Cyanistes';
        SELECT id INTO a_erith_g FROM dbnext.item WHERE name='Erithacus';
        SELECT id INTO a_parus_s FROM dbnext.item WHERE name='Parus major';
        SELECT id INTO a_cyan_s  FROM dbnext.item WHERE name='Cyanistes caeruleus';
        SELECT id INTO a_erith_s FROM dbnext.item WHERE name='Erithacus rubecula';
        SELECT id INTO a_cyan_syn FROM dbnext.item WHERE name='Parus caeruleus';
        it_parus := a_parus_s;

        INSERT INTO dbnext.item_list_item(id_item_list, id_item) VALUES (il_birds, a_aves) RETURNING id INTO ili_aves;
        INSERT INTO dbnext.item_list_item(id_item_list, id_item, id_parent) VALUES (il_birds, a_pass, ili_aves) RETURNING id INTO ili_pass;
        INSERT INTO dbnext.item_list_item(id_item_list, id_item, id_parent) VALUES (il_birds, a_parid, ili_pass) RETURNING id INTO ili_parid;
        INSERT INTO dbnext.item_list_item(id_item_list, id_item, id_parent) VALUES (il_birds, a_musc, ili_pass) RETURNING id INTO ili_musc;
        INSERT INTO dbnext.item_list_item(id_item_list, id_item, id_parent) VALUES (il_birds, a_parus_g, ili_parid) RETURNING id INTO ili_parus_g;
        INSERT INTO dbnext.item_list_item(id_item_list, id_item, id_parent) VALUES (il_birds, a_cyan_g, ili_parid) RETURNING id INTO ili_cyan_g;
        INSERT INTO dbnext.item_list_item(id_item_list, id_item, id_parent) VALUES (il_birds, a_erith_g, ili_musc) RETURNING id INTO ili_erith_g;
        INSERT INTO dbnext.item_list_item(id_item_list, id_item, id_parent) VALUES (il_birds, a_parus_s, ili_parus_g) RETURNING id INTO ili_parus;
        INSERT INTO dbnext.item_list_item(id_item_list, id_item, id_parent) VALUES (il_birds, a_cyan_s, ili_cyan_g) RETURNING id INTO ili_cyan;
        INSERT INTO dbnext.item_list_item(id_item_list, id_item, id_parent) VALUES (il_birds, a_erith_s, ili_erith_g) RETURNING id INTO ili_erith;
        -- synonym: Parus caeruleus -> accepted Cyanistes caeruleus (same identity group)
        INSERT INTO dbnext.item_list_item(id_item_list, id_item, id_parent, id_identity, id_accepted)
            VALUES (il_birds, a_cyan_syn, ili_cyan_g, ili_cyan, ili_cyan) RETURNING id INTO ili_cyan_syn;
        UPDATE dbnext.item_list_item SET id_identity = ili_cyan WHERE id = ili_cyan;

        -- multilingual common names linked to Parus major via identity group
        INSERT INTO dbnext.item(language, data, name) VALUES ('en','{}'::jsonb,'Great Tit') RETURNING id INTO i_common;
        INSERT INTO dbnext.item_list_item(id_item_list, id_item, id_parent, id_identity)
            VALUES (il_birds, i_common, ili_parus_g, ili_parus);
        INSERT INTO dbnext.item(language, data, name) VALUES ('de','{}'::jsonb,'Kohlmeise') RETURNING id INTO i_common;
        INSERT INTO dbnext.item_list_item(id_item_list, id_item, id_parent, id_identity)
            VALUES (il_birds, i_common, ili_parus_g, ili_parus);

        -- tag the endangered-free birds as least concern at item level
        INSERT INTO dbnext.item_keyword(id_item, id_keyword) VALUES
            (a_parus_s, k_dom_obs), (a_cyan_s, k_dom_obs);
    END;

    -- ---- PLANTS taxonomy (Plantae > Fagaceae > genus > species) ----
    DECLARE
        b_plantae bigint; b_fag bigint; b_quercus bigint; b_fagus bigint;
        b_qrobur bigint; b_qpetraea bigint; b_fsylv bigint;
        ili_plantae bigint; ili_fagaceae bigint; ili_quercus bigint;
        -- NB: ili_fagus is declared in the OUTER block (used later by r_c3) — do
        -- not re-declare it here or the species id won't propagate.
    BEGIN
        INSERT INTO dbnext.item(language, data, name) VALUES
            ('la','{}'::jsonb,'Plantae'),('la','{}'::jsonb,'Fagaceae'),
            ('la','{}'::jsonb,'Quercus'),('la','{}'::jsonb,'Fagus'),
            ('la','{}'::jsonb,'Quercus robur'),('la','{}'::jsonb,'Quercus petraea'),
            ('la','{}'::jsonb,'Fagus sylvatica');
        SELECT id INTO b_plantae  FROM dbnext.item WHERE name='Plantae';
        SELECT id INTO b_fag      FROM dbnext.item WHERE name='Fagaceae';
        SELECT id INTO b_quercus  FROM dbnext.item WHERE name='Quercus';
        SELECT id INTO b_fagus    FROM dbnext.item WHERE name='Fagus';
        SELECT id INTO b_qrobur   FROM dbnext.item WHERE name='Quercus robur';
        SELECT id INTO b_qpetraea FROM dbnext.item WHERE name='Quercus petraea';
        SELECT id INTO b_fsylv    FROM dbnext.item WHERE name='Fagus sylvatica';
        it_qrobur := b_qrobur;

        INSERT INTO dbnext.item_list_item(id_item_list, id_item) VALUES (il_plants, b_plantae) RETURNING id INTO ili_plantae;
        INSERT INTO dbnext.item_list_item(id_item_list, id_item, id_parent) VALUES (il_plants, b_fag, ili_plantae) RETURNING id INTO ili_fagaceae;
        INSERT INTO dbnext.item_list_item(id_item_list, id_item, id_parent) VALUES (il_plants, b_quercus, ili_fagaceae) RETURNING id INTO ili_quercus;
        INSERT INTO dbnext.item_list_item(id_item_list, id_item, id_parent) VALUES (il_plants, b_fagus, ili_fagaceae) RETURNING id INTO ili_fagus;
        INSERT INTO dbnext.item_list_item(id_item_list, id_item, id_parent) VALUES (il_plants, b_qrobur, ili_quercus) RETURNING id INTO ili_qrobur;
        INSERT INTO dbnext.item_list_item(id_item_list, id_item, id_parent) VALUES (il_plants, b_qpetraea, ili_quercus) RETURNING id INTO ili_qpetraea;
        INSERT INTO dbnext.item_list_item(id_item_list, id_item, id_parent) VALUES (il_plants, b_fsylv, ili_fagus) RETURNING id INTO ili_fagus; -- reuse var safely below
        SELECT id INTO ili_fagus FROM dbnext.item_list_item WHERE id_item_list=il_plants AND id_item=b_fsylv;
    END;

    -- ---- FOSSIL taxonomy (class > genus > species) ----
    DECLARE
        f_trilo bigint; f_ammo bigint;
        f_paradox_g bigint; f_calymene_g bigint; f_dactyl_g bigint;
        f_paradox_s bigint; f_calymene_s bigint; f_dactyl_s bigint;
        ili_trilo bigint; ili_ammo bigint;
        ili_paradox_g bigint; ili_calymene_g bigint; ili_dactyl_g bigint;
    BEGIN
        INSERT INTO dbnext.item(language, data, name) VALUES
            ('la','{}'::jsonb,'Trilobita'),('la','{}'::jsonb,'Ammonoidea'),
            ('la','{}'::jsonb,'Paradoxides'),('la','{}'::jsonb,'Calymene'),('la','{}'::jsonb,'Dactylioceras'),
            ('la','{}'::jsonb,'Paradoxides paradoxissimus'),('la','{}'::jsonb,'Calymene blumenbachii'),
            ('la','{}'::jsonb,'Dactylioceras commune');
        SELECT id INTO f_trilo      FROM dbnext.item WHERE name='Trilobita';
        SELECT id INTO f_ammo       FROM dbnext.item WHERE name='Ammonoidea';
        SELECT id INTO f_paradox_g  FROM dbnext.item WHERE name='Paradoxides';
        SELECT id INTO f_calymene_g FROM dbnext.item WHERE name='Calymene';
        SELECT id INTO f_dactyl_g   FROM dbnext.item WHERE name='Dactylioceras';
        SELECT id INTO f_paradox_s  FROM dbnext.item WHERE name='Paradoxides paradoxissimus';
        SELECT id INTO f_calymene_s FROM dbnext.item WHERE name='Calymene blumenbachii';
        SELECT id INTO f_dactyl_s   FROM dbnext.item WHERE name='Dactylioceras commune';

        INSERT INTO dbnext.item_list_item(id_item_list, id_item) VALUES (il_fossils, f_trilo) RETURNING id INTO ili_trilo;
        INSERT INTO dbnext.item_list_item(id_item_list, id_item) VALUES (il_fossils, f_ammo) RETURNING id INTO ili_ammo;
        INSERT INTO dbnext.item_list_item(id_item_list, id_item, id_parent) VALUES (il_fossils, f_paradox_g, ili_trilo) RETURNING id INTO ili_paradox_g;
        INSERT INTO dbnext.item_list_item(id_item_list, id_item, id_parent) VALUES (il_fossils, f_calymene_g, ili_trilo) RETURNING id INTO ili_calymene_g;
        INSERT INTO dbnext.item_list_item(id_item_list, id_item, id_parent) VALUES (il_fossils, f_dactyl_g, ili_ammo) RETURNING id INTO ili_dactyl_g;
        INSERT INTO dbnext.item_list_item(id_item_list, id_item, id_parent) VALUES (il_fossils, f_paradox_s, ili_paradox_g) RETURNING id INTO ili_paradox;
        INSERT INTO dbnext.item_list_item(id_item_list, id_item, id_parent) VALUES (il_fossils, f_calymene_s, ili_calymene_g) RETURNING id INTO ili_calymene;
        INSERT INTO dbnext.item_list_item(id_item_list, id_item, id_parent) VALUES (il_fossils, f_dactyl_s, ili_dactyl_g) RETURNING id INTO ili_dactyl;
    END;

    -- ---- MINERAL species (flat list) ----
    DECLARE
        m_quartz bigint; m_pyrite bigint; m_calcite bigint; m_fluorite bigint; m_galena bigint;
    BEGIN
        INSERT INTO dbnext.item(language, data, name) VALUES
            ('en','{}'::jsonb,'Quartz'),('en','{}'::jsonb,'Pyrite'),('en','{}'::jsonb,'Calcite'),
            ('en','{}'::jsonb,'Fluorite'),('en','{}'::jsonb,'Galena');
        SELECT id INTO m_quartz   FROM dbnext.item WHERE name='Quartz';
        SELECT id INTO m_pyrite   FROM dbnext.item WHERE name='Pyrite';
        SELECT id INTO m_calcite  FROM dbnext.item WHERE name='Calcite';
        SELECT id INTO m_fluorite FROM dbnext.item WHERE name='Fluorite';
        SELECT id INTO m_galena   FROM dbnext.item WHERE name='Galena';
        it_quartz := m_quartz;

        INSERT INTO dbnext.item_list_item(id_item_list, id_item) VALUES (il_minerals, m_quartz)   RETURNING id INTO ili_quartz;
        INSERT INTO dbnext.item_list_item(id_item_list, id_item) VALUES (il_minerals, m_pyrite)   RETURNING id INTO ili_pyrite;
        INSERT INTO dbnext.item_list_item(id_item_list, id_item) VALUES (il_minerals, m_calcite)  RETURNING id INTO ili_calcite;
        INSERT INTO dbnext.item_list_item(id_item_list, id_item) VALUES (il_minerals, m_fluorite) RETURNING id INTO ili_fluorite;
        INSERT INTO dbnext.item_list_item(id_item_list, id_item) VALUES (il_minerals, m_galena)   RETURNING id INTO ili_galena;

        -- classify mineral species items + list entries by Mineral Class
        INSERT INTO dbnext.item_list_item_keyword(id_item_list_item, id_keyword) VALUES
            (ili_quartz,   (SELECT id FROM dbnext.keyword WHERE name='silicates'  AND id_parent=k_minclass)),
            (ili_pyrite,   (SELECT id FROM dbnext.keyword WHERE name='sulfides'   AND id_parent=k_minclass)),
            (ili_calcite,  (SELECT id FROM dbnext.keyword WHERE name='carbonates' AND id_parent=k_minclass)),
            (ili_fluorite, (SELECT id FROM dbnext.keyword WHERE name='halides'    AND id_parent=k_minclass)),
            (ili_galena,   (SELECT id FROM dbnext.keyword WHERE name='sulfides'   AND id_parent=k_minclass));
    END;

    ------------------------------------------------------------------
    -- 6. wire projects: data groups, keywords, item lists
    ------------------------------------------------------------------
    UPDATE dbnext.project SET id_user=v_admin, id_data_group=dg_biodiv WHERE id=p_obs;
    UPDATE dbnext.project SET id_user=v_admin, id_data_group=dg_biodiv WHERE id=p_coll;
    UPDATE dbnext.project SET id_user=v_admin, id_data_group=dg_paleo  WHERE id=p_paleo;
    UPDATE dbnext.project SET id_user=v_admin, id_data_group=dg_mineral WHERE id=p_min;

    INSERT INTO dbnext.project_record_data_group(id_project, id_data_group, sort) VALUES
        (p_obs, dg_biodiv, 1), (p_coll, dg_biodiv, 1), (p_paleo, dg_paleo, 1), (p_min, dg_mineral, 1);

    INSERT INTO dbnext.project_keyword(id_project, id_keyword) VALUES
        (p_obs, k_dom_obs), (p_coll, k_dom_coll), (p_paleo, k_dom_paleo), (p_min, k_dom_min);

    INSERT INTO dbnext.project_item_list(id_project, id_item_list, preferred) VALUES
        (p_obs,   il_birds,    true),
        (p_coll,  il_plants,   true),
        (p_coll,  il_birds,    false),
        (p_paleo, il_fossils,  true),
        (p_min,   il_minerals, true);

    ------------------------------------------------------------------
    -- 7. OBSERVATIONS (project 7) — point sightings, no physical specimen
    ------------------------------------------------------------------
    INSERT INTO dbnext.project_record(data, date_start, created_by) VALUES
        ('{"abundance":3,"life_stage":"adult","sex":"male"}'::jsonb, '2024-05-12 08:30+02', v_admin) RETURNING id INTO r_o1;
    INSERT INTO dbnext.project_record(data, date_start, created_by) VALUES
        ('{"abundance":2,"life_stage":"adult"}'::jsonb, '2024-06-01 07:15+02', v_admin) RETURNING id INTO r_o2;
    INSERT INTO dbnext.project_record(data, date_start, created_by) VALUES
        ('{"abundance":1,"life_stage":"adult"}'::jsonb, '2023-11-03 09:00+01', v_admin) RETURNING id INTO r_o3;
    INSERT INTO dbnext.project_record(data, date_start, created_by) VALUES
        ('{"abundance":5,"life_stage":"juvenile"}'::jsonb, '2024-01-15 10:45+01', v_admin) RETURNING id INTO r_o4;

    INSERT INTO dbnext.project_record_project(id_project_record, id_project) VALUES
        (r_o1,p_obs),(r_o2,p_obs),(r_o3,p_obs),(r_o4,p_obs);

    INSERT INTO dbnext.project_record_geometry(id_project_record, geom) VALUES
        (r_o1, public.ST_SetSRID(public.ST_MakePoint(16.3738,48.2082),4326)),
        (r_o2, public.ST_SetSRID(public.ST_MakePoint(16.4000,48.1900),4326)),
        (r_o3, public.ST_SetSRID(public.ST_MakePoint(11.5820,48.1351),4326)),
        (r_o4, public.ST_SetSRID(public.ST_MakePoint(16.3600,48.2100),4326));

    INSERT INTO dbnext.project_record_determination(id_project_record, id_item_list_item, preferred, determined_by, determination_date, id_determination_method) VALUES
        (r_o1, ili_parus, true, u_jean, '2024-05-12', k_morph),
        (r_o2, ili_cyan,  true, u_jean, '2024-06-01', k_morph),
        (r_o3, ili_erith, true, u_maria,'2023-11-03', k_morph),
        (r_o4, ili_parus, true, u_maria,'2024-01-15', k_morph);

    -- domain + conservation tags
    INSERT INTO dbnext.project_record_keyword(id_project_record, id_keyword) VALUES
        (r_o1,k_dom_obs),(r_o2,k_dom_obs),(r_o3,k_dom_obs),(r_o4,k_dom_obs),
        (r_o1,(SELECT id FROM dbnext.keyword WHERE name='least concern' AND id_parent=k_conserv)),
        (r_o2,(SELECT id FROM dbnext.keyword WHERE name='least concern' AND id_parent=k_conserv)),
        (r_o3,(SELECT id FROM dbnext.keyword WHERE name='least concern' AND id_parent=k_conserv));

    -- observers
    INSERT INTO dbnext.project_record_user(id_user, id_project_record) VALUES (u_maria, r_o1) RETURNING id INTO v_pru;
    INSERT INTO dbnext.project_record_user_keyword(id_project_record_user, id_keyword) VALUES (v_pru, k_observer);
    INSERT INTO dbnext.project_record_user(id_user, id_project_record) VALUES (u_jean, r_o2) RETURNING id INTO v_pru;
    INSERT INTO dbnext.project_record_user_keyword(id_project_record_user, id_keyword) VALUES (v_pru, k_observer);

    -- external identifiers
    INSERT INTO dbnext.external_identifier(source, identifier, url, description)
        VALUES ('GBIF','4510690','https://www.gbif.org/occurrence/4510690','GBIF occurrence') RETURNING id INTO v_ext;
    INSERT INTO dbnext.external_identifier_project_record(id_external_identifier, id_project_record) VALUES (v_ext, r_o1);
    INSERT INTO dbnext.external_identifier(source, identifier, url, description)
        VALUES ('iNaturalist','198765432','https://www.inaturalist.org/observations/198765432','iNat observation') RETURNING id INTO v_ext;
    INSERT INTO dbnext.external_identifier_project_record(id_external_identifier, id_project_record) VALUES (v_ext, r_o2);

    ------------------------------------------------------------------
    -- 8. LIFE-SCIENCE COLLECTIONS (project 8) — preserved specimens
    ------------------------------------------------------------------
    INSERT INTO dbnext.project_record(data, date_start, date_end, created_by) VALUES
        ('{}'::jsonb, '1998-07-20', '1998-07-20', v_admin) RETURNING id INTO r_c1;
    INSERT INTO dbnext.project_record(data, date_start, date_end, created_by) VALUES
        ('{}'::jsonb, '1998-07-20', '1998-07-20', v_admin) RETURNING id INTO r_c2;
    INSERT INTO dbnext.project_record(data, date_start, date_end, created_by) VALUES
        ('{}'::jsonb, '2005-09-10', '2005-09-10', v_admin) RETURNING id INTO r_c3;
    INSERT INTO dbnext.project_record(data, date_start, date_end, created_by) VALUES
        ('{}'::jsonb, '1975-06-04', '1975-06-04', v_admin) RETURNING id INTO r_c4;

    INSERT INTO dbnext.project_record_project(id_project_record, id_project) VALUES
        (r_c1,p_coll),(r_c2,p_coll),(r_c3,p_coll),(r_c4,p_coll);

    INSERT INTO dbnext.project_record_geometry(id_project_record, geom) VALUES
        (r_c1, public.ST_SetSRID(public.ST_MakePoint(8.5417,47.3769),4326)),
        (r_c2, public.ST_SetSRID(public.ST_MakePoint(8.5417,47.3769),4326)),
        (r_c3, public.ST_SetSRID(public.ST_MakePoint(7.4474,46.9480),4326)),
        (r_c4, public.ST_SetSRID(public.ST_MakePoint(13.3777,52.5163),4326));

    INSERT INTO dbnext.project_record_determination(id_project_record, id_item_list_item, preferred, determined_by, determination_date, id_determination_method)
        VALUES (r_c1, ili_qrobur, true, u_jean, '1999-02-10', k_morph) RETURNING id INTO det_c1;
    INSERT INTO dbnext.project_record_determination_keyword(id_project_record_determination, id_keyword)
        VALUES (det_c1, k_molecular);  -- later confirmed by DNA barcoding
    INSERT INTO dbnext.project_record_determination(id_project_record, id_item_list_item, preferred, determined_by, id_determination_method) VALUES
        (r_c2, ili_qrobur,   true, u_jean, k_morph),
        (r_c3, ili_fagus,    true, u_jean, k_morph);
    -- historical determiner recorded as free text (determined_by_name)
    INSERT INTO dbnext.project_record_determination(id_project_record, id_item_list_item, preferred, determined_by_name, determination_date, id_determination_method)
        VALUES (r_c4, ili_qpetraea, true, 'C. Linnaeus', '1975-08-01', k_morph);

    INSERT INTO dbnext.project_record_identifier(id_project_record, id_keyword, value) VALUES
        (r_c1, k_catalog, 'HERB-2001'), (r_c1, k_barcode, 'BOLD:AAB1234'),
        (r_c2, k_catalog, 'HERB-2002'),
        (r_c3, k_catalog, 'HERB-3050'),
        (r_c4, k_catalog, 'HERB-T001');

    -- domain + preservation + sample-type + type-status tags
    INSERT INTO dbnext.project_record_keyword(id_project_record, id_keyword) VALUES
        (r_c1,k_dom_coll),(r_c2,k_dom_coll),(r_c3,k_dom_coll),(r_c4,k_dom_coll),
        (r_c1,(SELECT id FROM dbnext.keyword WHERE name='dried/herbarium' AND id_parent=k_preserv)),
        (r_c2,(SELECT id FROM dbnext.keyword WHERE name='dried/herbarium' AND id_parent=k_preserv)),
        (r_c1,(SELECT id FROM dbnext.keyword WHERE name='leaf' AND id_parent=k_sampletype)),
        (r_c4,(SELECT id FROM dbnext.keyword WHERE name='holotype' AND id_parent=k_typestatus)),
        (r_c4,(SELECT id FROM dbnext.keyword WHERE name='dried/herbarium' AND id_parent=k_preserv));

    -- collector + determiner on r_c1
    INSERT INTO dbnext.project_record_user(id_user, id_project_record) VALUES (u_maria, r_c1) RETURNING id INTO v_pru;
    INSERT INTO dbnext.project_record_user_keyword(id_project_record_user, id_keyword) VALUES (v_pru, k_collector);
    INSERT INTO dbnext.project_record_user(id_user, id_project_record) VALUES (u_jean, r_c1) RETURNING id INTO v_pru;
    INSERT INTO dbnext.project_record_user_keyword(id_project_record_user, id_keyword) VALUES (v_pru, k_determiner);

    -- duplicate herbarium sheets: c1 <-> c2 (same collection, distributed)
    INSERT INTO dbnext.project_record_record(id_project_record_1, id_project_record_2, id_keyword, description) VALUES
        (r_c1, r_c2, k_dupof, 'duplicate sheets of the same gathering'),
        (r_c2, r_c1, k_dupof, 'duplicate sheets of the same gathering');

    -- external identifiers
    INSERT INTO dbnext.external_identifier(source, identifier, url, description)
        VALUES ('Index Herbariorum','Z','https://sweetgum.nybg.org/science/ih/herbarium-details/?irn=124000','herbarium code') RETURNING id INTO v_ext;
    INSERT INTO dbnext.external_identifier_project_record(id_external_identifier, id_project_record) VALUES (v_ext, r_c1);
    INSERT INTO dbnext.external_identifier(source, identifier, url, description)
        VALUES ('BOLD','AAB1234','https://www.boldsystems.org/index.php/Public_RecordView?processid=AAB1234','DNA barcode record') RETURNING id INTO v_ext;
    INSERT INTO dbnext.external_identifier_project_record(id_external_identifier, id_project_record) VALUES (v_ext, r_c1);
    INSERT INTO dbnext.external_identifier_item(id_external_identifier, id_item) VALUES (v_ext, it_qrobur);

    ------------------------------------------------------------------
    -- 9. PALEONTOLOGY (project 9) — fossils, geological time in jsonb
    ------------------------------------------------------------------
    INSERT INTO dbnext.project_record(data, created_by) VALUES
        ('{"period":"Cambrian","formation":"Alum Shale","stage":"Drumian"}'::jsonb, v_admin) RETURNING id INTO r_p1;
    INSERT INTO dbnext.project_record(data, created_by) VALUES
        ('{"period":"Jurassic","formation":"Whitby Mudstone","stage":"Toarcian"}'::jsonb, v_admin) RETURNING id INTO r_p2;
    INSERT INTO dbnext.project_record(data, created_by) VALUES
        ('{"period":"Silurian","formation":"Wenlock Limestone","stage":"Homerian"}'::jsonb, v_admin) RETURNING id INTO r_p3;
    INSERT INTO dbnext.project_record(data, created_by) VALUES
        ('{"period":"Cambrian","formation":"Alum Shale"}'::jsonb, v_admin) RETURNING id INTO r_plot;
    INSERT INTO dbnext.project_record(data, created_by) VALUES
        ('{"period":"Cambrian","preparation":"thin section"}'::jsonb, v_admin) RETURNING id INTO r_pthin;

    INSERT INTO dbnext.project_record_project(id_project_record, id_project) VALUES
        (r_p1,p_paleo),(r_p2,p_paleo),(r_p3,p_paleo),(r_plot,p_paleo),(r_pthin,p_paleo);

    INSERT INTO dbnext.project_record_geometry(id_project_record, geom) VALUES
        (r_p1, public.ST_SetSRID(public.ST_MakePoint(14.5906,58.4109),4326)),  -- Sweden
        (r_p2, public.ST_SetSRID(public.ST_MakePoint(-0.6139,54.4858),4326)),  -- Whitby, UK
        (r_p3, public.ST_SetSRID(public.ST_MakePoint(-2.6160,52.4000),4326)),  -- Wenlock, UK
        (r_plot, public.ST_SetSRID(public.ST_MakePoint(14.5906,58.4109),4326));

    INSERT INTO dbnext.project_record_determination(id_project_record, id_item_list_item, preferred, determined_by, id_determination_method) VALUES
        (r_p1, ili_paradox,  true, u_jean, k_morph),
        (r_p2, ili_dactyl,   true, u_jean, k_morph),
        (r_p3, ili_calymene, true, u_maria, k_morph),
        (r_plot, ili_paradox, true, u_jean, k_morph);

    INSERT INTO dbnext.project_record_identifier(id_project_record, id_keyword, value) VALUES
        (r_p1, k_accession, 'PAL-1001'),
        (r_p2, k_accession, 'PAL-2002'),
        (r_p3, k_accession, 'PAL-1500'),
        (r_plot, k_accession, 'PAL-LOT-01'),
        (r_pthin, k_accession, 'PAL-LOT-01-TS1');

    -- domain + geological-period keyword tags
    INSERT INTO dbnext.project_record_keyword(id_project_record, id_keyword) VALUES
        (r_p1,k_dom_paleo),(r_p2,k_dom_paleo),(r_p3,k_dom_paleo),(r_plot,k_dom_paleo),(r_pthin,k_dom_paleo),
        (r_p1,(SELECT id FROM dbnext.keyword WHERE name='Cambrian' AND id_parent=k_period)),
        (r_p2,(SELECT id FROM dbnext.keyword WHERE name='Jurassic' AND id_parent=k_period)),
        (r_p3,(SELECT id FROM dbnext.keyword WHERE name='Silurian' AND id_parent=k_period)),
        (r_plot,(SELECT id FROM dbnext.keyword WHERE name='Cambrian' AND id_parent=k_period)),
        (r_p1,(SELECT id FROM dbnext.keyword WHERE name='rock sample' AND id_parent=k_sampletype)),
        (r_pthin,(SELECT id FROM dbnext.keyword WHERE name='thin section' AND id_parent=k_sampletype));

    -- bulk lot -> thin section (child derived from parent)
    INSERT INTO dbnext.project_record_parent(id_project_record, id_project_record_parent, id_keyword, description)
        VALUES (r_pthin, r_plot, k_derived, 'thin section cut from bulk lot');

    INSERT INTO dbnext.external_identifier(source, identifier, url, description)
        VALUES ('PBDB','taxon:12345','https://paleobiodb.org/classic/checkTaxonInfo?taxon_no=12345','Paleobiology Database') RETURNING id INTO v_ext;
    INSERT INTO dbnext.external_identifier_project_record(id_external_identifier, id_project_record) VALUES (v_ext, r_p1);

    ------------------------------------------------------------------
    -- 10. MINERALOGY (project 10) — mineral specimens
    ------------------------------------------------------------------
    INSERT INTO dbnext.project_record(data, created_by) VALUES
        ('{"crystal_system":"trigonal","mohs_hardness":"7","chemical_formula":"SiO2"}'::jsonb, v_admin) RETURNING id INTO r_m1;
    INSERT INTO dbnext.project_record(data, created_by) VALUES
        ('{"crystal_system":"cubic","mohs_hardness":"6-6.5","chemical_formula":"FeS2"}'::jsonb, v_admin) RETURNING id INTO r_m2;
    INSERT INTO dbnext.project_record(data, created_by) VALUES
        ('{"crystal_system":"trigonal","mohs_hardness":"3","chemical_formula":"CaCO3"}'::jsonb, v_admin) RETURNING id INTO r_m3;
    INSERT INTO dbnext.project_record(data, created_by) VALUES
        ('{"crystal_system":"cubic","mohs_hardness":"4","chemical_formula":"CaF2"}'::jsonb, v_admin) RETURNING id INTO r_m4;
    INSERT INTO dbnext.project_record(data, created_by) VALUES
        ('{"crystal_system":"cubic","mohs_hardness":"2.5","chemical_formula":"PbS"}'::jsonb, v_admin) RETURNING id INTO r_mlot;
    INSERT INTO dbnext.project_record(data, created_by) VALUES
        ('{"crystal_system":"cubic","preparation":"polished section"}'::jsonb, v_admin) RETURNING id INTO r_mpol;

    INSERT INTO dbnext.project_record_project(id_project_record, id_project) VALUES
        (r_m1,p_min),(r_m2,p_min),(r_m3,p_min),(r_m4,p_min),(r_mlot,p_min),(r_mpol,p_min);

    INSERT INTO dbnext.project_record_geometry(id_project_record, geom) VALUES
        (r_m1, public.ST_SetSRID(public.ST_MakePoint(7.0,46.0),4326)),
        (r_m2, public.ST_SetSRID(public.ST_MakePoint(-4.1,40.5),4326)),   -- Spain
        (r_m3, public.ST_SetSRID(public.ST_MakePoint(11.0,46.5),4326)),
        (r_m4, public.ST_SetSRID(public.ST_MakePoint(-2.0,54.5),4326)),   -- England (fluorite)
        (r_mlot, public.ST_SetSRID(public.ST_MakePoint(12.9,51.2),4326)); -- Freiberg, Saxony

    INSERT INTO dbnext.project_record_determination(id_project_record, id_item_list_item, preferred, determined_by, id_determination_method) VALUES
        (r_m1, ili_quartz,   true, u_maria, k_xrd),
        (r_m2, ili_pyrite,   true, u_maria, k_xrd),
        (r_m3, ili_calcite,  true, u_maria, k_xrd),
        (r_m4, ili_fluorite, true, u_maria, k_xrd),
        (r_mlot, ili_galena, true, u_maria, k_xrd);

    INSERT INTO dbnext.project_record_identifier(id_project_record, id_keyword, value) VALUES
        (r_m1, k_catalog, 'MIN-1001'),
        (r_m1, (SELECT id FROM dbnext.keyword WHERE name='Mindat ID' AND id_parent=k_idtype), '380'),
        (r_m2, k_catalog, 'MIN-1002'),
        (r_m3, k_catalog, 'MIN-1003'),
        (r_m4, k_catalog, 'MIN-1004'),
        (r_mlot, k_catalog, 'MIN-LOT-02');

    -- domain + mineral-class + type-locality tags
    INSERT INTO dbnext.project_record_keyword(id_project_record, id_keyword) VALUES
        (r_m1,k_dom_min),(r_m2,k_dom_min),(r_m3,k_dom_min),(r_m4,k_dom_min),(r_mlot,k_dom_min),(r_mpol,k_dom_min),
        (r_m1,(SELECT id FROM dbnext.keyword WHERE name='silicates'  AND id_parent=k_minclass)),
        (r_m2,(SELECT id FROM dbnext.keyword WHERE name='sulfides'   AND id_parent=k_minclass)),
        (r_m3,(SELECT id FROM dbnext.keyword WHERE name='carbonates' AND id_parent=k_minclass)),
        (r_m4,(SELECT id FROM dbnext.keyword WHERE name='halides'    AND id_parent=k_minclass)),
        (r_mlot,(SELECT id FROM dbnext.keyword WHERE name='sulfides' AND id_parent=k_minclass)),
        (r_m4,(SELECT id FROM dbnext.keyword WHERE name='type locality' AND id_parent=k_typestatus)),
        (r_mlot,(SELECT id FROM dbnext.keyword WHERE name='rock sample' AND id_parent=k_sampletype)),
        (r_mpol,(SELECT id FROM dbnext.keyword WHERE name='thin section' AND id_parent=k_sampletype));

    -- ore sample -> polished section
    INSERT INTO dbnext.project_record_parent(id_project_record, id_project_record_parent, id_keyword, description)
        VALUES (r_mpol, r_mlot, k_derived, 'polished section prepared from ore sample');

    INSERT INTO dbnext.external_identifier(source, identifier, url, description)
        VALUES ('Mindat','380','https://www.mindat.org/min-3337.html','Mindat mineral page (Quartz)') RETURNING id INTO v_ext;
    INSERT INTO dbnext.external_identifier_project_record(id_external_identifier, id_project_record) VALUES (v_ext, r_m1);
    INSERT INTO dbnext.external_identifier_item(id_external_identifier, id_item) VALUES (v_ext, it_quartz);

    ------------------------------------------------------------------
    -- 11. media (metadata only; files live outside the DB)
    ------------------------------------------------------------------
    INSERT INTO dbnext.media(id_data_group, data, file_path, mime_type, description, created_by)
        VALUES (dg_media,'{}'::jsonb,'https://media.demo.museum/img/quercus_robur_001.jpg','image/jpeg','Quercus robur herbarium sheet', v_admin) RETURNING id INTO v_med;
    INSERT INTO dbnext.media_item(id_media, id_item) VALUES (v_med, it_qrobur);
    INSERT INTO dbnext.project_record_media(id_media, id_project_record) VALUES (v_med, r_c1);

    INSERT INTO dbnext.media(id_data_group, data, file_path, mime_type, description, created_by)
        VALUES (dg_media,'{}'::jsonb,'https://media.demo.museum/img/parus_major_field.jpg','image/jpeg','Great Tit field photo', v_admin) RETURNING id INTO v_med;
    INSERT INTO dbnext.media_item(id_media, id_item) VALUES (v_med, it_parus);
    INSERT INTO dbnext.project_record_media(id_media, id_project_record) VALUES (v_med, r_o1);

    INSERT INTO dbnext.media(id_data_group, data, file_path, mime_type, description, created_by)
        VALUES (dg_media,'{}'::jsonb,'https://media.demo.museum/img/quartz_xtal.jpg','image/jpeg','Quartz crystal specimen', v_admin) RETURNING id INTO v_med;
    INSERT INTO dbnext.media_item(id_media, id_item) VALUES (v_med, it_quartz);
    INSERT INTO dbnext.project_record_media(id_media, id_project_record) VALUES (v_med, r_m1);

    -- taxon lineage (branch / rank / classification) is added afterwards by
    -- sql/seed_taxon_branch.sql — run it as the last seed step.

    RAISE NOTICE 'demo seed loaded: 4 taxonomies, % records across projects 7-10',
        (SELECT count(*) FROM dbnext.project_record_project
         WHERE id_project IN (p_obs,p_coll,p_paleo,p_min));
END
$seed$;

COMMIT;
