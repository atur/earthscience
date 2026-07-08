--
-- seed_relations_data.sql — locations & collection stores as records, wired
-- to the domain records.
--
-- 1. LOCATIONS: a hierarchical item_list (Country > Locality). Each locality
--    becomes a project_record (in a new "Locations" project) with a point
--    geometry and a determination to its locality item. Every domain record
--    (projects 7-10) is then attached as a CHILD of the nearest locality via
--    project_record_parent (keyword "collected at").
--
-- 2. COLLECTION STORES: a hierarchical item_list (Building > Room > Cabinet).
--    Each cabinet becomes a project_record (in a new "Collection Stores"
--    project). Every COLLECTION specimen (projects 8,9,10 — observations in 7
--    are not physical) is linked to a store of its domain via
--    project_record_record (keyword "stored in").
--
-- Run AFTER seed_test_data.sql and seed_bulk_data.sql so the links cover the
-- full dataset. IDEMPOTENT via the root keyword `demo-rel-seed`.
-- Remove with seed_relations_teardown.sql.
--

SET client_encoding TO 'UTF8';

BEGIN;

DO $rel$
DECLARE
    v_admin   bigint := 13;
    dg_list bigint; dg_item bigint;
    k_reltype bigint; k_collectedat bigint; k_stored bigint;
    P_loc bigint; P_store bigint;
    L_loc bigint; L_store bigint;

    cfg RECORD;
    ranks text[];
    i int; col text; pcol_expr text;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM dbnext.keyword WHERE name='demo-seed' AND id_parent IS NULL) THEN
        RAISE EXCEPTION 'curated demo seed not found — run seed_test_data.sql first';
    END IF;
    IF EXISTS (SELECT 1 FROM dbnext.keyword WHERE name='demo-rel-seed' AND id_parent IS NULL) THEN
        RAISE NOTICE 'relations seed already present — skipping (run seed_relations_teardown.sql to reset)';
        RETURN;
    END IF;

    SELECT id INTO dg_list   FROM dbnext.data_group WHERE name='demo: taxonomy list fields';
    SELECT id INTO dg_item   FROM dbnext.data_group WHERE name='demo: taxon item fields';
    SELECT id INTO k_reltype FROM dbnext.keyword WHERE name='Relationship Type' AND id_parent IS NULL;

    INSERT INTO dbnext.keyword(name, description, id_data_group)
        VALUES ('demo-rel-seed','marker: rows created by seed_relations_data.sql',
                (SELECT id FROM dbnext.data_group WHERE name='demo: keyword metadata'));
    INSERT INTO dbnext.keyword(id_parent, name, description) VALUES
        (k_reltype, 'collected at', 'record was collected/observed at this location'),
        (k_reltype, 'stored in',    'specimen is physically stored in this collection store');
    SELECT id INTO k_collectedat FROM dbnext.keyword WHERE name='collected at' AND id_parent=k_reltype;
    SELECT id INTO k_stored      FROM dbnext.keyword WHERE name='stored in'    AND id_parent=k_reltype;

    ------------------------------------------------------------------
    -- new projects to host the location / store records
    ------------------------------------------------------------------
    INSERT INTO dbnext.project(name, description, id_user)
        VALUES ('Locations','localities the records were collected/observed at', v_admin)
        RETURNING id INTO P_loc;
    INSERT INTO dbnext.project(name, description, id_user)
        VALUES ('Collection Stores','physical storage units (building/room/cabinet)', v_admin)
        RETURNING id INTO P_store;

    INSERT INTO dbnext.item_list(name, description, data, item_list_id_data_group, item_id_data_group, created_by)
    VALUES ('Locations','collecting localities (country > locality)','{}'::jsonb, dg_list, dg_item, v_admin),
           ('Collection Stores','storage hierarchy (building > room > cabinet)','{}'::jsonb, dg_list, dg_item, v_admin);
    SELECT id INTO L_loc   FROM dbnext.item_list WHERE name='Locations';
    SELECT id INTO L_store FROM dbnext.item_list WHERE name='Collection Stores';

    ------------------------------------------------------------------
    -- source data
    ------------------------------------------------------------------
    CREATE TEMP TABLE loc_src(country text, locality text, lon float8, lat float8) ON COMMIT DROP;
    INSERT INTO loc_src VALUES
    ('Austria','Vienna',16.3738,48.2082),
    ('Austria','Hallstatt',13.6493,47.5622),
    ('Germany','Solnhofen',11.0049,48.8949),
    ('Germany','Freiberg',13.3428,50.9156),
    ('Germany','Messel',8.7570,49.9170),
    ('Germany','Munich',11.5820,48.1351),
    ('United Kingdom','Whitby',-0.6139,54.4858),
    ('United Kingdom','Much Wenlock',-2.5610,52.5970),
    ('United Kingdom','Lyme Regis',-2.9430,50.7256),
    ('France','Paris',2.3522,48.8566),
    ('France','Cap Blanc-Nez',1.7010,50.9230),
    ('Switzerland','Zurich',8.5417,47.3769),
    ('Switzerland','Monte San Giorgio',8.9200,45.9000),
    ('Italy','Bolca',11.2000,45.6000),
    ('Spain','Las Hoyas',-2.0000,40.1000),
    ('Spain','Almaden',-4.8330,38.7740),
    ('Sweden','Kinnekulle',13.4000,58.5800),
    ('United States','Hell Creek',-106.0000,47.5000),
    ('United States','Green River',-109.5000,41.6000),
    ('United States','Carlsbad',-104.5000,32.4000),
    ('Canada','Burgess Shale',-116.4760,51.4360),
    ('Morocco','Erfoud',-4.2300,31.5000),
    ('China','Liaoning',121.5000,41.6000),
    ('Argentina','Ischigualasto',-68.0000,-30.0000),
    ('Australia','Broken Hill',141.4500,-31.9500),
    ('Brazil','Araripe',-39.7000,-7.2000);

    CREATE TEMP TABLE store_src(building text, room text, cabinet text, domain_proj bigint) ON COMMIT DROP;
    INSERT INTO store_src VALUES
    ('Botany Wing','Herbarium Hall','Herbarium Cabinet H1',8),
    ('Botany Wing','Herbarium Hall','Herbarium Cabinet H2',8),
    ('Zoology Wing','Wet Collection Room','Spirit Jar Shelf Z1',8),
    ('Zoology Wing','Dry Skin Room','Bird Skin Drawer Z2',8),
    ('Earth Sciences','Paleontology Store','Fossil Drawer P1',9),
    ('Earth Sciences','Paleontology Store','Fossil Drawer P2',9),
    ('Earth Sciences','Paleontology Store','Type Specimen Safe P3',9),
    ('Earth Sciences','Mineral Vault','Mineral Cabinet M1',10),
    ('Earth Sciences','Mineral Vault','Mineral Cabinet M2',10),
    ('Earth Sciences','Mineral Vault','Gem Safe M3',10);

    ------------------------------------------------------------------
    -- generic hierarchy builder (same approach as seed_bulk_data.sql)
    ------------------------------------------------------------------
    CREATE TEMP TABLE tmp_nodes(list bigint, rank text, name text, ili_id bigint, item_id bigint) ON COMMIT DROP;

    FOR cfg IN
        SELECT * FROM (VALUES
            (L_loc,  'loc_src',   ARRAY['country','locality']),
            (L_store,'store_src', ARRAY['building','room','cabinet'])
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
                    SELECT 'en','{}'::jsonb, name FROM names
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

    ------------------------------------------------------------------
    -- LOCATION records (one per locality) + geometry + determination
    ------------------------------------------------------------------
    CREATE TEMP TABLE loc_rec ON COMMIT DROP AS
    SELECT nextval('dbnext.project_record_id_seq') AS rec_id, n.ili_id,
           s.country, s.locality, s.lon, s.lat,
           public.ST_SetSRID(public.ST_MakePoint(s.lon, s.lat),4326) AS geom
    FROM tmp_nodes n JOIN loc_src s ON s.locality = n.name
    WHERE n.list = L_loc AND n.rank = 'locality';

    INSERT INTO dbnext.project_record(id, data, created_by)
        SELECT rec_id, jsonb_build_object('country',country,'locality',locality), v_admin FROM loc_rec;
    INSERT INTO dbnext.project_record_project(id_project_record, id_project) SELECT rec_id, P_loc FROM loc_rec;
    INSERT INTO dbnext.project_record_geometry(id_record, geom) SELECT rec_id, geom FROM loc_rec;
    INSERT INTO dbnext.project_record_determination(id_project_record, id_item_list_item, preferred)
        SELECT rec_id, ili_id, true FROM loc_rec;

    ------------------------------------------------------------------
    -- STORE records (one per cabinet) + determination
    ------------------------------------------------------------------
    CREATE TEMP TABLE store_rec ON COMMIT DROP AS
    SELECT nextval('dbnext.project_record_id_seq') AS rec_id, n.ili_id,
           s.building, s.room, s.cabinet, s.domain_proj
    FROM tmp_nodes n JOIN store_src s ON s.cabinet = n.name
    WHERE n.list = L_store AND n.rank = 'cabinet';

    INSERT INTO dbnext.project_record(id, data, created_by)
        SELECT rec_id, jsonb_build_object('building',building,'room',room,'cabinet',cabinet), v_admin FROM store_rec;
    INSERT INTO dbnext.project_record_project(id_project_record, id_project) SELECT rec_id, P_store FROM store_rec;
    INSERT INTO dbnext.project_record_determination(id_project_record, id_item_list_item, preferred)
        SELECT rec_id, ili_id, true FROM store_rec;

    ------------------------------------------------------------------
    -- 1. attach every domain record (7-10) to its NEAREST locality
    ------------------------------------------------------------------
    CREATE TEMP TABLE dom ON COMMIT DROP AS
    SELECT DISTINCT ON (g.id_record) g.id_record AS rec_id, g.geom
    FROM dbnext.project_record_geometry g
    JOIN dbnext.project_record_project prp ON prp.id_project_record = g.id_record
    WHERE prp.id_project IN (7,8,9,10);

    INSERT INTO dbnext.project_record_parent(id_project_record, id_project_record_parent, id_keyword)
    SELECT d.rec_id, loc.rec_id, k_collectedat
    FROM dom d
    CROSS JOIN LATERAL (
        SELECT rec_id FROM loc_rec ORDER BY d.geom <-> loc_rec.geom LIMIT 1
    ) loc
    ON CONFLICT ON CONSTRAINT uq_project_record_parent_pair DO NOTHING;

    ------------------------------------------------------------------
    -- 2. link every COLLECTION specimen (8,9,10) to a store of its domain
    ------------------------------------------------------------------
    INSERT INTO dbnext.project_record_record(id_project_record_1, id_project_record_2, id_keyword)
    SELECT spec.rec_id, sa.a[1 + floor(random()*sa.c)::int], k_stored
    FROM (
        SELECT DISTINCT prp.id_project_record AS rec_id, prp.id_project AS proj
        FROM dbnext.project_record_project prp
        WHERE prp.id_project IN (8,9,10)
    ) spec
    JOIN (
        SELECT domain_proj, array_agg(rec_id) a, count(*)::int c
        FROM store_rec GROUP BY domain_proj
    ) sa ON sa.domain_proj = spec.proj
    ON CONFLICT ON CONSTRAINT uq_project_record_record_pair DO NOTHING;

    RAISE NOTICE 'relations seed loaded: % localities, % stores, % location links, % store links',
        (SELECT count(*) FROM loc_rec),
        (SELECT count(*) FROM store_rec),
        (SELECT count(*) FROM dbnext.project_record_parent WHERE id_keyword=k_collectedat),
        (SELECT count(*) FROM dbnext.project_record_record  WHERE id_keyword=k_stored);
END
$rel$;

COMMIT;
