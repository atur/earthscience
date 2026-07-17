--
-- seed_teardown.sql — remove everything created by seed_test_data.sql
--
-- Safe to run repeatedly. Deletes only the demo rows (identified by the
-- `demo:`-prefixed data_groups, the demo taxonomies, the demo users and the
-- records sitting in the four domain projects 7-10). Deleting the demo
-- project_records cascades to all their child/link tables. The four projects
-- (7-10) and the Domain keyword tree (40/42-45) are pre-existing scaffold and
-- are NOT deleted — only un-wired (their demo data_group / item_list / keyword
-- links are cleared).
--
-- Run in pgAdmin (paste + F5) or: psql ... -f sql/seed_teardown.sql
--

BEGIN;

DO $td$
DECLARE
    p_ids bigint[] := ARRAY[7, 8, 9, 10];
    dg_ids bigint[];
    il_ids bigint[];
    u_ids  bigint[];
    rec    bigint;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM dbnext.keyword
                   WHERE name = 'demo-seed' AND id_parent IS NULL) THEN
        RAISE NOTICE 'no demo seed present — nothing to do';
        RETURN;
    END IF;

    SELECT array_agg(id) INTO dg_ids FROM dbnext.data_group WHERE name LIKE 'demo:%';
    SELECT array_agg(id) INTO il_ids FROM dbnext.item_list
        WHERE name IN ('Birds of Central Europe','Vascular Plants','Fossil Taxa','Mineral Species');
    SELECT array_agg(id) INTO u_ids FROM dbnext.users
        WHERE email IN ('maria.hofer@demo.museum','jean.petit@demo.museum');

    ----------------------------------------------------------------
    -- 1. project_records in the demo projects. Deleting them cascades
    --    to determinations, geometry, identifiers, keywords, users,
    --    parent/peer links, media links and external-id links.
    --    The deferred "last project/determination" guards short-circuit
    --    because the parent record is deleted in the same statement.
    ----------------------------------------------------------------
    FOR rec IN
        SELECT DISTINCT prp.id_project_record
        FROM dbnext.project_record_project prp
        WHERE prp.id_project = ANY(p_ids)
    LOOP
        DELETE FROM dbnext.project_record WHERE id = rec;
    END LOOP;

    ----------------------------------------------------------------
    -- 2. un-wire the projects from demo data_groups / item_lists / keywords
    ----------------------------------------------------------------
    DELETE FROM dbnext.project_record_data_group WHERE id_project = ANY(p_ids);
    DELETE FROM dbnext.project_item_list         WHERE id_project = ANY(p_ids);
    DELETE FROM dbnext.project_keyword           WHERE id_project = ANY(p_ids);
    UPDATE dbnext.project
        SET id_data_group = NULL
        WHERE id = ANY(p_ids);

    ----------------------------------------------------------------
    -- 3. taxonomies (item_list_item -> item_list -> orphan items)
    ----------------------------------------------------------------
    IF il_ids IS NOT NULL THEN
        DELETE FROM dbnext.item_list_item_keyword
            WHERE id_item_list_item IN (
                SELECT id FROM dbnext.item_list_item WHERE id_item_list = ANY(il_ids));
        -- clear self-references first so rows can be deleted in any order
        UPDATE dbnext.item_list_item
            SET id_parent = NULL, id_identity = NULL, id_accepted = NULL
            WHERE id_item_list = ANY(il_ids);
        DELETE FROM dbnext.item_list_item WHERE id_item_list = ANY(il_ids);
        DELETE FROM dbnext.item_list_keyword WHERE id_item_list = ANY(il_ids);
        DELETE FROM dbnext.item_list WHERE id = ANY(il_ids);
    END IF;
    -- items left with no list membership and no other references
    DELETE FROM dbnext.media_item mi
        WHERE NOT EXISTS (SELECT 1 FROM dbnext.item_list_item ili WHERE ili.id_item = mi.id_item);
    DELETE FROM dbnext.external_identifier_item eii
        WHERE NOT EXISTS (SELECT 1 FROM dbnext.item_list_item ili WHERE ili.id_item = eii.id_item);
    DELETE FROM dbnext.item_keyword ik
        WHERE NOT EXISTS (SELECT 1 FROM dbnext.item_list_item ili WHERE ili.id_item = ik.id_item);
    DELETE FROM dbnext.item i
        WHERE NOT EXISTS (SELECT 1 FROM dbnext.item_list_item ili WHERE ili.id_item = i.id);

    ----------------------------------------------------------------
    -- 4. media, external identifiers, users, keywords, data groups
    ----------------------------------------------------------------
    DELETE FROM dbnext.media WHERE file_path LIKE 'https://media.demo.museum/%';
    DELETE FROM dbnext.external_identifier
        WHERE source IN ('GBIF','iNaturalist','Index Herbariorum','BOLD','PBDB','Mindat');

    IF u_ids IS NOT NULL THEN
        DELETE FROM dbnext.users_keyword WHERE id_user = ANY(u_ids);
        DELETE FROM dbnext.users WHERE id = ANY(u_ids);
    END IF;

    -- demo keywords: delete leaves before parents (depth-first) and the sentinel
    DELETE FROM dbnext.keyword WHERE id_data_group = ANY(dg_ids) AND id_parent IS NOT NULL;
    DELETE FROM dbnext.keyword WHERE id_data_group = ANY(dg_ids) AND id_parent IS NULL;

    DELETE FROM dbnext.data_definition WHERE id_group = ANY(dg_ids);
    DELETE FROM dbnext.data_group WHERE id = ANY(dg_ids);

    RAISE NOTICE 'demo seed removed';
END
$td$;

COMMIT;
