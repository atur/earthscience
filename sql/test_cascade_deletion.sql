--
-- Cascade-deletion + guard-trigger test
--
-- pgAdmin 4: open the Query Tool against the dbnext database, paste this
-- whole file, and press F5 (Execute). Look at the "Messages" pane for
-- "PASS" / "FAIL" / "ALL TESTS PASSED" lines. Any ASSERT or unexpected
-- exception aborts execution and the final ROLLBACK leaves no residue.
--
-- The script is wrapped in a single transaction that always ROLLBACKs.
-- It contains no psql meta-commands, so it runs unchanged in pgAdmin.
--

BEGIN;

DO $test$
DECLARE
    -- shared bits
    v_dg            bigint;
    v_user1         bigint;
    v_user2         bigint;
    v_project       bigint;
    v_item          bigint;
    v_item_list     bigint;
    v_ili           bigint;
    v_kw_collector  bigint;
    v_kw_dup        bigint;
    v_kw_partof     bigint;
    v_kw_catalog    bigint;
    v_kw_morph      bigint;
    v_kw_dettype    bigint;
    v_media         bigint;
    v_ext           bigint;

    -- the four project_records: main is the cascade target,
    -- the others provide the "other end" for parent/peer relations
    v_pr_main       bigint;
    v_pr_parent     bigint;
    v_pr_child      bigint;
    v_pr_peer       bigint;

    v_pru           bigint;  -- project_record_user row tied to v_pr_main
    v_prd           bigint;  -- project_record_determination tied to v_pr_main

    cnt             bigint;
    v_caught        text;
BEGIN
    ----------------------------------------------------------------
    -- 1. fixture: shared lookup rows
    ----------------------------------------------------------------
    INSERT INTO dbnext.data_group (name, description)
        VALUES ('cascade-test-dg', 'shared dg for cascade test')
        RETURNING id INTO v_dg;

    INSERT INTO dbnext.users (name, email)
        VALUES ('Collector A', 'collector-a@cascade.test')
        RETURNING id INTO v_user1;
    INSERT INTO dbnext.users (name, email)
        VALUES ('Determiner B', 'determiner-b@cascade.test')
        RETURNING id INTO v_user2;

    INSERT INTO dbnext.project
        (name, description, data, id_data_group, id_user)
        VALUES ('Cascade Test Project', '', '{}'::jsonb, v_dg, v_user1)
        RETURNING id INTO v_project;

    INSERT INTO dbnext.item (language, data, name)
        VALUES ('en', '{}'::jsonb, 'Quercus robur')
        RETURNING id INTO v_item;
    INSERT INTO dbnext.item_list
        (name, description, data, item_list_id_data_group, item_list_item_id_data_group)
        VALUES ('Test Taxonomy', '', '{}'::jsonb, v_dg, v_dg)
        RETURNING id INTO v_item_list;
    INSERT INTO dbnext.item_list_item (id_item_list, id_item)
        VALUES (v_item_list, v_item)
        RETURNING id INTO v_ili;

    INSERT INTO dbnext.keyword (name, description, data, id_data_group)
        VALUES ('collector', '', '{}'::jsonb, v_dg)
        RETURNING id INTO v_kw_collector;
    INSERT INTO dbnext.keyword (name, description, data, id_data_group)
        VALUES ('duplicate-of', '', '{}'::jsonb, v_dg)
        RETURNING id INTO v_kw_dup;
    INSERT INTO dbnext.keyword (name, description, data, id_data_group)
        VALUES ('part-of', '', '{}'::jsonb, v_dg)
        RETURNING id INTO v_kw_partof;
    INSERT INTO dbnext.keyword (name, description, data, id_data_group)
        VALUES ('catalog-no', '', '{}'::jsonb, v_dg)
        RETURNING id INTO v_kw_catalog;
    INSERT INTO dbnext.keyword (name, description, data, id_data_group)
        VALUES ('morphological', '', '{}'::jsonb, v_dg)
        RETURNING id INTO v_kw_morph;
    INSERT INTO dbnext.keyword (name, description, data, id_data_group)
        VALUES ('original-determination', '', '{}'::jsonb, v_dg)
        RETURNING id INTO v_kw_dettype;

    INSERT INTO dbnext.media
        (id_data_group, data, file_path, mime_type, description)
        VALUES (v_dg, '{}'::jsonb, '/tmp/test.jpg', 'image/jpeg', 'test image')
        RETURNING id INTO v_media;

    INSERT INTO dbnext.external_identifier (source, identifier, description)
        VALUES ('GBIF', 'TEST-12345', 'test gbif id')
        RETURNING id INTO v_ext;

    ----------------------------------------------------------------
    -- 2. four project_records (deferred guards mean we can insert
    --    the project_record_project + determination rows after)
    ----------------------------------------------------------------
    INSERT INTO dbnext.project_record (data) VALUES ('{"obs":"main"}'::jsonb)
        RETURNING id INTO v_pr_main;
    INSERT INTO dbnext.project_record (data) VALUES ('{"obs":"parent"}'::jsonb)
        RETURNING id INTO v_pr_parent;
    INSERT INTO dbnext.project_record (data) VALUES ('{"obs":"child"}'::jsonb)
        RETURNING id INTO v_pr_child;
    INSERT INTO dbnext.project_record (data) VALUES ('{"obs":"peer"}'::jsonb)
        RETURNING id INTO v_pr_peer;

    INSERT INTO dbnext.project_record_project (id_project_record, id_project)
        VALUES (v_pr_main,   v_project),
               (v_pr_parent, v_project),
               (v_pr_child,  v_project),
               (v_pr_peer,   v_project);

    -- every project_record needs at least one determination later, but the
    -- guard on determination is only against deletes — inserts are fine.
    INSERT INTO dbnext.project_record_determination
        (id_project_record, id_item_list_item, preferred,
         determined_by, id_determination_method)
        VALUES (v_pr_main, v_ili, true, v_user2, v_kw_morph)
        RETURNING id INTO v_prd;
    INSERT INTO dbnext.project_record_determination
        (id_project_record, id_item_list_item, preferred)
        VALUES (v_pr_parent, v_ili, true);
    INSERT INTO dbnext.project_record_determination
        (id_project_record, id_item_list_item, preferred)
        VALUES (v_pr_child, v_ili, true);
    INSERT INTO dbnext.project_record_determination
        (id_project_record, id_item_list_item, preferred)
        VALUES (v_pr_peer, v_ili, true);

    ----------------------------------------------------------------
    -- 3. wire v_pr_main into every child / link table
    ----------------------------------------------------------------
    -- (1) external_identifier_project_record
    INSERT INTO dbnext.external_identifier_project_record
        (id_external_identifier, id_project_record)
        VALUES (v_ext, v_pr_main);

    -- (2) project_record_geometry
    INSERT INTO dbnext.project_record_geometry (id_project_record, geom)
        VALUES (v_pr_main,
                public.ST_SetSRID(public.ST_MakePoint(8.55, 47.37), 4326));

    -- (3) project_record_media
    INSERT INTO dbnext.project_record_media (id_media, id_project_record)
        VALUES (v_media, v_pr_main);

    -- (4) project_record_identifier
    INSERT INTO dbnext.project_record_identifier
        (id_project_record, id_keyword, value)
        VALUES (v_pr_main, v_kw_catalog, 'CAT-001');

    -- (5) project_record_keyword
    INSERT INTO dbnext.project_record_keyword
        (id_project_record, id_keyword, description)
        VALUES (v_pr_main, v_kw_dup, 'tag');

    -- (6) project_record_user + (grandchild) project_record_user_keyword
    INSERT INTO dbnext.project_record_user (id_user, id_project_record)
        VALUES (v_user1, v_pr_main)
        RETURNING id INTO v_pru;
    INSERT INTO dbnext.project_record_user_keyword
        (id_project_record_user, id_keyword)
        VALUES (v_pru, v_kw_collector);

    -- (7) (grandchild) project_record_determination_keyword on v_prd
    INSERT INTO dbnext.project_record_determination_keyword
        (id_project_record_determination, id_keyword)
        VALUES (v_prd, v_kw_dettype);

    -- (8) project_record_parent — both directions
    INSERT INTO dbnext.project_record_parent
        (id_project_record, id_project_record_parent, id_keyword)
        VALUES (v_pr_main, v_pr_parent, v_kw_partof);  -- main -> parent
    INSERT INTO dbnext.project_record_parent
        (id_project_record, id_project_record_parent, id_keyword)
        VALUES (v_pr_child, v_pr_main, v_kw_partof);   -- child -> main

    -- (9) project_record_record — both directions
    INSERT INTO dbnext.project_record_record
        (id_project_record_1, id_project_record_2, id_keyword)
        VALUES (v_pr_main, v_pr_peer, v_kw_dup);
    INSERT INTO dbnext.project_record_record
        (id_project_record_1, id_project_record_2, id_keyword)
        VALUES (v_pr_peer, v_pr_main, v_kw_dup);

    ----------------------------------------------------------------
    -- 4. baseline: confirm fan-out is in place
    ----------------------------------------------------------------
    SELECT
        (SELECT count(*) FROM dbnext.external_identifier_project_record
           WHERE id_project_record = v_pr_main)
      + (SELECT count(*) FROM dbnext.project_record_geometry
           WHERE id_project_record = v_pr_main)
      + (SELECT count(*) FROM dbnext.project_record_media
           WHERE id_project_record = v_pr_main)
      + (SELECT count(*) FROM dbnext.project_record_identifier
           WHERE id_project_record = v_pr_main)
      + (SELECT count(*) FROM dbnext.project_record_keyword
           WHERE id_project_record = v_pr_main)
      + (SELECT count(*) FROM dbnext.project_record_user
           WHERE id_project_record = v_pr_main)
      + (SELECT count(*) FROM dbnext.project_record_user_keyword
           WHERE id_project_record_user = v_pru)
      + (SELECT count(*) FROM dbnext.project_record_determination
           WHERE id_project_record = v_pr_main)
      + (SELECT count(*) FROM dbnext.project_record_determination_keyword
           WHERE id_project_record_determination = v_prd)
      + (SELECT count(*) FROM dbnext.project_record_project
           WHERE id_project_record = v_pr_main)
      + (SELECT count(*) FROM dbnext.project_record_parent
           WHERE id_project_record = v_pr_main
              OR id_project_record_parent = v_pr_main)
      + (SELECT count(*) FROM dbnext.project_record_record
           WHERE id_project_record_1 = v_pr_main
              OR id_project_record_2 = v_pr_main)
        INTO cnt;
    ASSERT cnt = 14,
        format('baseline fan-out: expected 14 rows, got %s', cnt);
    RAISE NOTICE 'baseline OK: % child rows attached to v_pr_main', cnt;

    ----------------------------------------------------------------
    -- TEST 1: DELETE FROM project_record cascades to all children
    ----------------------------------------------------------------
    DELETE FROM dbnext.project_record WHERE id = v_pr_main;

    -- Force the two AFTER-DELETE guards to fire here so we can verify their
    -- cascade short-circuit clauses. We deliberately do NOT fire ALL
    -- constraints: the AFTER-INSERT trg_project_record_requires_project
    -- still has a pending event from v_pr_main's earlier INSERT, and that
    -- check would now (correctly) fail because its association was just
    -- cascade-deleted. Only the two AFTER-DELETE triggers are under test.
    SET CONSTRAINTS
        dbnext.trg_prevent_last_project_association_delete,
        dbnext.trg_prevent_last_determination_delete
        IMMEDIATE;

    SELECT count(*) INTO cnt
        FROM dbnext.external_identifier_project_record
        WHERE id_project_record = v_pr_main;
    ASSERT cnt = 0, 'external_identifier_project_record not cascaded';

    SELECT count(*) INTO cnt
        FROM dbnext.project_record_geometry
        WHERE id_project_record = v_pr_main;
    ASSERT cnt = 0, 'project_record_geometry not cascaded';

    SELECT count(*) INTO cnt
        FROM dbnext.project_record_media
        WHERE id_project_record = v_pr_main;
    ASSERT cnt = 0, 'project_record_media not cascaded';

    SELECT count(*) INTO cnt
        FROM dbnext.project_record_identifier
        WHERE id_project_record = v_pr_main;
    ASSERT cnt = 0, 'project_record_identifier not cascaded';

    SELECT count(*) INTO cnt
        FROM dbnext.project_record_keyword
        WHERE id_project_record = v_pr_main;
    ASSERT cnt = 0, 'project_record_keyword not cascaded';

    SELECT count(*) INTO cnt
        FROM dbnext.project_record_user
        WHERE id_project_record = v_pr_main;
    ASSERT cnt = 0, 'project_record_user not cascaded';

    -- grandchild: project_record_user_keyword
    SELECT count(*) INTO cnt
        FROM dbnext.project_record_user_keyword
        WHERE id_project_record_user = v_pru;
    ASSERT cnt = 0, 'project_record_user_keyword grandchild not cascaded';

    SELECT count(*) INTO cnt
        FROM dbnext.project_record_determination
        WHERE id_project_record = v_pr_main;
    ASSERT cnt = 0, 'project_record_determination not cascaded';

    -- grandchild: project_record_determination_keyword
    SELECT count(*) INTO cnt
        FROM dbnext.project_record_determination_keyword
        WHERE id_project_record_determination = v_prd;
    ASSERT cnt = 0, 'project_record_determination_keyword grandchild not cascaded';

    SELECT count(*) INTO cnt
        FROM dbnext.project_record_project
        WHERE id_project_record = v_pr_main;
    ASSERT cnt = 0, 'project_record_project not cascaded';

    SELECT count(*) INTO cnt
        FROM dbnext.project_record_parent
        WHERE id_project_record = v_pr_main
           OR id_project_record_parent = v_pr_main;
    ASSERT cnt = 0,
        'project_record_parent not cascaded (either direction)';

    SELECT count(*) INTO cnt
        FROM dbnext.project_record_record
        WHERE id_project_record_1 = v_pr_main
           OR id_project_record_2 = v_pr_main;
    ASSERT cnt = 0,
        'project_record_record not cascaded (either direction)';

    -- The companion records are still around (they were not the target).
    SELECT count(*) INTO cnt
        FROM dbnext.project_record
        WHERE id IN (v_pr_parent, v_pr_child, v_pr_peer);
    ASSERT cnt = 3, 'companion project_records were unexpectedly removed';

    RAISE NOTICE 'TEST 1 PASS: cascade delete cleared all 12 children + 2 grandchildren';

    ----------------------------------------------------------------
    -- TEST 2: project_record without project_record_project is rejected
    ----------------------------------------------------------------
    BEGIN
        INSERT INTO dbnext.project_record (data) VALUES ('{"orphan":true}'::jsonb);
        SET CONSTRAINTS dbnext.trg_project_record_requires_project IMMEDIATE;
        v_caught := 'NONE';
    EXCEPTION
        WHEN foreign_key_violation THEN
            v_caught := SQLERRM;
    END;

    IF v_caught = 'NONE' THEN
        RAISE EXCEPTION 'TEST 2 FAIL: orphan project_record was accepted';
    END IF;
    RAISE NOTICE 'TEST 2 PASS: orphan project_record rejected (%)', v_caught;

    ----------------------------------------------------------------
    -- TEST 3: deleting the LAST project_record_project is rejected
    -- (v_pr_parent is still around with exactly one association)
    ----------------------------------------------------------------
    BEGIN
        DELETE FROM dbnext.project_record_project
            WHERE id_project_record = v_pr_parent;
        SET CONSTRAINTS dbnext.trg_prevent_last_project_association_delete IMMEDIATE;
        v_caught := 'NONE';
    EXCEPTION
        WHEN restrict_violation THEN
            v_caught := SQLERRM;
    END;

    IF v_caught = 'NONE' THEN
        RAISE EXCEPTION 'TEST 3 FAIL: last project_record_project was deleted';
    END IF;
    RAISE NOTICE 'TEST 3 PASS: last project_record_project rejected (%)', v_caught;

    ----------------------------------------------------------------
    -- TEST 4: deleting the LAST determination is rejected
    ----------------------------------------------------------------
    BEGIN
        DELETE FROM dbnext.project_record_determination
            WHERE id_project_record = v_pr_parent;
        SET CONSTRAINTS dbnext.trg_prevent_last_determination_delete IMMEDIATE;
        v_caught := 'NONE';
    EXCEPTION
        WHEN restrict_violation THEN
            v_caught := SQLERRM;
    END;

    IF v_caught = 'NONE' THEN
        RAISE EXCEPTION 'TEST 4 FAIL: last determination was deleted';
    END IF;
    RAISE NOTICE 'TEST 4 PASS: last determination rejected (%)', v_caught;

    RAISE NOTICE 'ALL TESTS PASSED';
END
$test$;

-- Always roll back so the test leaves no residue.
ROLLBACK;
