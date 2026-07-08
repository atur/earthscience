--
-- seed_relations_teardown.sql — remove everything created by
-- seed_relations_data.sql (locations + collection stores + their links).
--
-- Deleting the location/store records cascades and clears the
-- project_record_parent ("collected at") and project_record_record
-- ("stored in") links automatically (both FK sides are ON DELETE CASCADE).
--
-- Safe to run repeatedly.
--

BEGIN;

DO $td$
DECLARE
    p_ids  bigint[];
    il_ids bigint[];
    rec bigint;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM dbnext.keyword WHERE name='demo-rel-seed' AND id_parent IS NULL) THEN
        RAISE NOTICE 'no relations seed present — nothing to do';
        RETURN;
    END IF;

    SELECT array_agg(id) INTO p_ids  FROM dbnext.project   WHERE name IN ('Locations','Collection Stores');
    SELECT array_agg(id) INTO il_ids FROM dbnext.item_list WHERE name IN ('Locations','Collection Stores');

    -- 1. delete the location/store records (cascades to their geometry,
    --    determinations and to the collected-at / stored-in links)
    IF p_ids IS NOT NULL THEN
        FOR rec IN
            SELECT DISTINCT id_project_record FROM dbnext.project_record_project
            WHERE id_project = ANY(p_ids)
        LOOP
            DELETE FROM dbnext.project_record WHERE id = rec;
        END LOOP;
        DELETE FROM dbnext.project WHERE id = ANY(p_ids);
    END IF;

    -- 2. taxonomies
    IF il_ids IS NOT NULL THEN
        UPDATE dbnext.item_list_item
            SET id_parent = NULL, id_identity = NULL, id_accepted = NULL
            WHERE id_item_list = ANY(il_ids);
        DELETE FROM dbnext.item_list_item WHERE id_item_list = ANY(il_ids);
        DELETE FROM dbnext.item_list_keyword WHERE id_item_list = ANY(il_ids);
        DELETE FROM dbnext.item_list WHERE id = ANY(il_ids);
    END IF;
    DELETE FROM dbnext.item i
        WHERE NOT EXISTS (SELECT 1 FROM dbnext.item_list_item ili WHERE ili.id_item = i.id)
          AND NOT EXISTS (SELECT 1 FROM dbnext.media_item mi WHERE mi.id_item = i.id)
          AND NOT EXISTS (SELECT 1 FROM dbnext.external_identifier_item ei WHERE ei.id_item = i.id)
          AND NOT EXISTS (SELECT 1 FROM dbnext.item_keyword ik WHERE ik.id_item = i.id);

    -- 3. keywords (the two relationship types + sentinel)
    DELETE FROM dbnext.keyword WHERE name IN ('collected at','stored in')
        AND id_parent = (SELECT id FROM dbnext.keyword WHERE name='Relationship Type' AND id_parent IS NULL);
    DELETE FROM dbnext.keyword WHERE name='demo-rel-seed' AND id_parent IS NULL;

    RAISE NOTICE 'relations seed removed';
END
$td$;

COMMIT;
