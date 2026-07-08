--
-- seed_bulk_teardown.sql — remove everything created by seed_bulk_data.sql
--
-- Leaves the curated demo (seed_test_data.sql) and the pre-existing scaffold
-- intact. Bulk records are identified by their identifier prefixes
-- (LSO-/LSC-/PALB-/MINB-); deleting those records cascades to all children.
--
-- Safe to run repeatedly.
--

BEGIN;

DO $td$
DECLARE
    il_ids bigint[];
    rec bigint;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM dbnext.keyword WHERE name='demo-bulk-seed' AND id_parent IS NULL) THEN
        RAISE NOTICE 'no bulk seed present — nothing to do';
        RETURN;
    END IF;

    -- 1. delete bulk project_records (cascades to determinations, geometry,
    --    identifiers, keywords, users and external-id links)
    FOR rec IN
        SELECT DISTINCT id_project_record
        FROM dbnext.project_record_identifier
        WHERE value LIKE 'LSO-%' OR value LIKE 'LSC-%'
           OR value LIKE 'PALB-%' OR value LIKE 'MINB-%'
    LOOP
        DELETE FROM dbnext.project_record WHERE id = rec;
    END LOOP;

    -- 2. orphaned external identifiers created by the bulk seed
    DELETE FROM dbnext.external_identifier WHERE identifier LIKE 'OCC-%' AND source='GBIF';

    -- 3. bulk taxonomies
    SELECT array_agg(id) INTO il_ids FROM dbnext.item_list
        WHERE name IN ('Animalia - full taxonomy','Plantae - full taxonomy',
                       'Fossil taxa - full taxonomy','Mineral systematics');
    IF il_ids IS NOT NULL THEN
        UPDATE dbnext.item_list_item
            SET id_parent = NULL, id_identity = NULL, id_accepted = NULL
            WHERE id_item_list = ANY(il_ids);
        DELETE FROM dbnext.item_list_item WHERE id_item_list = ANY(il_ids);
        DELETE FROM dbnext.item_list_keyword WHERE id_item_list = ANY(il_ids);
        DELETE FROM dbnext.item_list WHERE id = ANY(il_ids);
    END IF;
    -- orphan items left by the bulk taxonomies (curated items stay — they are
    -- still referenced by the curated lists)
    DELETE FROM dbnext.item i
        WHERE NOT EXISTS (SELECT 1 FROM dbnext.item_list_item ili WHERE ili.id_item = i.id)
          AND NOT EXISTS (SELECT 1 FROM dbnext.media_item mi WHERE mi.id_item = i.id)
          AND NOT EXISTS (SELECT 1 FROM dbnext.external_identifier_item ei WHERE ei.id_item = i.id)
          AND NOT EXISTS (SELECT 1 FROM dbnext.item_keyword ik WHERE ik.id_item = i.id);

    -- 4. sentinel
    DELETE FROM dbnext.keyword WHERE name='demo-bulk-seed' AND id_parent IS NULL;

    RAISE NOTICE 'bulk seed removed';
END
$td$;

COMMIT;
