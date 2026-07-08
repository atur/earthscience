--
-- test_queries.sql — validation / demonstration queries for the demo seed
--
-- Run after seed_test_data.sql. Each query is read-only and headed by a
-- comment stating what it proves. Every query is expected to return >=1 row.
-- Exercises: PostGIS spatial, temporal tstzrange, jsonb custom fields,
-- pg_trgm fuzzy search, taxonomy hierarchy/synonymy, determinations and the
-- keyword-driven classification that ties the whole dataset together.
--
-- pgAdmin: open the Query Tool and run statements individually (place the
-- cursor in one and press F5), or run the whole file from psql.
--

----------------------------------------------------------------------
-- 1. SPATIAL (PostGIS) — records inside a Central-Europe bounding box.
--    Uses geom (SRID 4326) and the GiST index idx_prg_geom.
----------------------------------------------------------------------
SELECT pr.id, k.name AS domain, public.ST_AsText(g.geom) AS location
FROM dbnext.project_record_geometry g
JOIN dbnext.project_record pr ON pr.id = g.id_record
JOIN dbnext.project_record_keyword prk ON prk.id_project_record = pr.id
JOIN dbnext.keyword k ON k.id = prk.id_keyword AND k.id_parent = 40  -- Domain
WHERE g.geom && public.ST_MakeEnvelope(5, 45, 17, 59, 4326)
ORDER BY pr.id;

----------------------------------------------------------------------
-- 2. SPATIAL — records within 75 km of Vienna (geography distance).
----------------------------------------------------------------------
SELECT pr.id,
       round((public.ST_Distance(
                g.geom::geography,
                public.ST_SetSRID(public.ST_MakePoint(16.3738, 48.2082), 4326)::geography
              ) / 1000)::numeric, 1) AS km_from_vienna
FROM dbnext.project_record_geometry g
JOIN dbnext.project_record pr ON pr.id = g.id_record
WHERE public.ST_DWithin(
        g.geom::geography,
        public.ST_SetSRID(public.ST_MakePoint(16.3738, 48.2082), 4326)::geography,
        75000)
ORDER BY km_from_vienna;

----------------------------------------------------------------------
-- 3. TEMPORAL — records whose event date_range OVERLAPS calendar 2024.
--    Uses the generated tstzrange column and idx_project_record_date_range.
----------------------------------------------------------------------
SELECT id, date_start, date_end, date_range
FROM dbnext.project_record
WHERE date_range && tstzrange('2024-01-01', '2025-01-01', '[)')
ORDER BY date_start;

----------------------------------------------------------------------
-- 4. TEMPORAL — historical specimens collected within 1990..2010
--    (range containment with @>).
----------------------------------------------------------------------
SELECT id, date_start
FROM dbnext.project_record
WHERE tstzrange('1990-01-01', '2010-12-31', '[]') @> date_range
ORDER BY date_start;

----------------------------------------------------------------------
-- 5a. JSONB — fossils from the Jurassic (containment @>, uses GIN index).
----------------------------------------------------------------------
SELECT pr.id, pr.data ->> 'formation' AS formation, pr.data ->> 'stage' AS stage
FROM dbnext.project_record pr
WHERE pr.data @> '{"period":"Jurassic"}'::jsonb;

-- 5b. JSONB — all minerals with cubic crystal system.
SELECT pr.id, pr.data ->> 'chemical_formula' AS formula
FROM dbnext.project_record pr
WHERE pr.data @> '{"crystal_system":"cubic"}'::jsonb
ORDER BY pr.id;

----------------------------------------------------------------------
-- 6. pg_trgm — fuzzy name search on item.name (uses idx_item_name_trgm).
--    Finds 'Quercus ...' even with a typo, ranked by similarity.
----------------------------------------------------------------------
SELECT name, round(public.similarity(name, 'Quercas')::numeric, 3) AS sim
FROM dbnext.item
WHERE name % 'Quercas'
ORDER BY sim DESC, name;

----------------------------------------------------------------------
-- 7. TAXONOMY — full lineage of every species in the fossil list,
--    walking item_list_item.id_parent with a recursive CTE.
----------------------------------------------------------------------
WITH RECURSIVE tree AS (
    SELECT ili.id, ili.id_parent, i.name, i.name::text AS path
    FROM dbnext.item_list_item ili
    JOIN dbnext.item i ON i.id = ili.id_item
    WHERE ili.id_item_list = (SELECT id FROM dbnext.item_list WHERE name='Fossil Taxa')
      AND ili.id_parent IS NULL
    UNION ALL
    SELECT c.id, c.id_parent, ci.name, t.path || ' > ' || ci.name
    FROM dbnext.item_list_item c
    JOIN dbnext.item ci ON ci.id = c.id_item
    JOIN tree t ON c.id_parent = t.id
)
SELECT path FROM tree ORDER BY path;

----------------------------------------------------------------------
-- 8. SYNONYMY — resolve a synonym to its accepted name via id_accepted.
--    (Parus caeruleus -> Cyanistes caeruleus in the bird checklist.)
----------------------------------------------------------------------
SELECT syn_i.name AS synonym, acc_i.name AS accepted_name
FROM dbnext.item_list_item syn
JOIN dbnext.item syn_i ON syn_i.id = syn.id_item
JOIN dbnext.item_list_item acc ON acc.id = syn.id_accepted
JOIN dbnext.item acc_i ON acc_i.id = acc.id_item
WHERE syn.id_accepted IS NOT NULL AND syn.id <> syn.id_accepted;

----------------------------------------------------------------------
-- 9. DETERMINATIONS — preferred determination per record, with taxon name,
--    determiner (user or historical free text) and method keyword.
----------------------------------------------------------------------
SELECT pr.id AS record,
       i.name AS taxon,
       coalesce(u.name, d.determined_by_name) AS determined_by,
       m.name AS method
FROM dbnext.project_record_determination d
JOIN dbnext.project_record pr ON pr.id = d.id_project_record
JOIN dbnext.item_list_item ili ON ili.id = d.id_item_list_item
JOIN dbnext.item i ON i.id = ili.id_item
LEFT JOIN dbnext.users u ON u.id = d.determined_by
LEFT JOIN dbnext.keyword m ON m.id = d.id_determination_method
WHERE d.preferred
ORDER BY pr.id;

----------------------------------------------------------------------
-- 10. KEYWORDS — record count per domain (the Domain keyword tree, 40).
----------------------------------------------------------------------
SELECT k.name AS domain, count(*) AS records
FROM dbnext.project_record_keyword prk
JOIN dbnext.keyword k ON k.id = prk.id_keyword AND k.id_parent = 40
GROUP BY k.name
ORDER BY records DESC;

----------------------------------------------------------------------
-- 11. KEYWORDS — fossils grouped by Geological Period keyword.
----------------------------------------------------------------------
SELECT k.name AS period, count(*) AS fossils
FROM dbnext.project_record_keyword prk
JOIN dbnext.keyword k ON k.id = prk.id_keyword
JOIN dbnext.keyword p ON p.id = k.id_parent AND p.name = 'Geological Period'
GROUP BY k.name
ORDER BY fossils DESC, period;

----------------------------------------------------------------------
-- 12. KEYWORDS — minerals grouped by Mineral Class keyword.
----------------------------------------------------------------------
SELECT k.name AS mineral_class, count(*) AS specimens
FROM dbnext.project_record_keyword prk
JOIN dbnext.keyword k ON k.id = prk.id_keyword
JOIN dbnext.keyword p ON p.id = k.id_parent AND p.name = 'Mineral Class'
GROUP BY k.name
ORDER BY specimens DESC, mineral_class;

----------------------------------------------------------------------
-- 13. KEYWORDS — records carrying a nomenclatural type status.
----------------------------------------------------------------------
SELECT pr.id AS record, k.name AS type_status
FROM dbnext.project_record_keyword prk
JOIN dbnext.keyword k ON k.id = prk.id_keyword
JOIN dbnext.keyword p ON p.id = k.id_parent AND p.name = 'Specimen Type Status'
JOIN dbnext.project_record pr ON pr.id = prk.id_project_record
ORDER BY pr.id;

----------------------------------------------------------------------
-- 14. IDENTIFIERS — every record identifier grouped by its type keyword.
----------------------------------------------------------------------
SELECT k.name AS identifier_type, pri.value, pri.id_project_record AS record
FROM dbnext.project_record_identifier pri
JOIN dbnext.keyword k ON k.id = pri.id_keyword
ORDER BY k.name, pri.value;

----------------------------------------------------------------------
-- 15. PEOPLE — users on records with their role keyword.
----------------------------------------------------------------------
SELECT pr.id AS record, u.name AS person, k.name AS role
FROM dbnext.project_record_user pru
JOIN dbnext.users u ON u.id = pru.id_user
JOIN dbnext.project_record pr ON pr.id = pru.id_project_record
LEFT JOIN dbnext.project_record_user_keyword puk ON puk.id_project_record_user = pru.id
LEFT JOIN dbnext.keyword k ON k.id = puk.id_keyword
ORDER BY pr.id, role;

----------------------------------------------------------------------
-- 16. KEYWORD TREE — the whole controlled vocabulary as an indented tree.
----------------------------------------------------------------------
WITH RECURSIVE kw AS (
    SELECT id, id_parent, name, 0 AS depth, name::text AS path
    FROM dbnext.keyword WHERE id_parent IS NULL
    UNION ALL
    SELECT c.id, c.id_parent, c.name, kw.depth + 1, kw.path || ' / ' || c.name
    FROM dbnext.keyword c JOIN kw ON c.id_parent = kw.id
)
SELECT repeat('  ', depth) || name AS classification, path
FROM kw ORDER BY path;

----------------------------------------------------------------------
-- 17. RELATIONSHIPS — peer links (e.g. duplicate herbarium sheets),
--     typed by keyword. Stored both directions in the seed.
----------------------------------------------------------------------
SELECT rr.id_project_record_1 AS rec_a, rr.id_project_record_2 AS rec_b,
       k.name AS relationship, rr.description
FROM dbnext.project_record_record rr
JOIN dbnext.keyword k ON k.id = rr.id_keyword
ORDER BY rec_a, rec_b;

----------------------------------------------------------------------
-- 18. RELATIONSHIPS — parent/child derivation (lot -> thin/polished section).
----------------------------------------------------------------------
SELECT child.id_project_record AS child_record,
       child.id_project_record_parent AS parent_record,
       k.name AS relationship, child.description
FROM dbnext.project_record_parent child
JOIN dbnext.keyword k ON k.id = child.id_keyword
ORDER BY parent_record;

----------------------------------------------------------------------
-- 19. EXTERNAL IDENTIFIERS — cross-references attached to records.
----------------------------------------------------------------------
SELECT ei.source, ei.identifier, eipr.id_project_record AS record, ei.url
FROM dbnext.external_identifier ei
JOIN dbnext.external_identifier_project_record eipr
     ON eipr.id_external_identifier = ei.id
ORDER BY ei.source;

----------------------------------------------------------------------
-- 20. INTEGRITY — per-domain-project record/determination/geometry counts,
--     and a check that NO project_record is orphaned (must return 0).
----------------------------------------------------------------------
SELECT p.id AS project, p.name,
       count(DISTINCT prp.id_project_record) AS records,
       count(DISTINCT d.id)                  AS determinations,
       count(DISTINCT g.id)                  AS geometries
FROM dbnext.project p
LEFT JOIN dbnext.project_record_project prp ON prp.id_project = p.id
LEFT JOIN dbnext.project_record_determination d ON d.id_project_record = prp.id_project_record
LEFT JOIN dbnext.project_record_geometry g ON g.id_record = prp.id_project_record
WHERE p.id IN (7, 8, 9, 10)
GROUP BY p.id, p.name
ORDER BY p.id;

SELECT count(*) AS orphaned_records
FROM dbnext.project_record pr
WHERE NOT EXISTS (
    SELECT 1 FROM dbnext.project_record_project x
    WHERE x.id_project_record = pr.id);

----------------------------------------------------------------------
-- 21. LOCATIONS — how many domain records were collected at each locality
--     (records attached as children via project_record_parent).
----------------------------------------------------------------------
SELECT loc.data ->> 'country'  AS country,
       loc.data ->> 'locality' AS locality,
       count(*) AS records_collected_here
FROM dbnext.project_record_parent pp
JOIN dbnext.keyword k ON k.id = pp.id_keyword AND k.name = 'collected at'
JOIN dbnext.project_record loc ON loc.id = pp.id_project_record_parent
GROUP BY 1, 2
ORDER BY records_collected_here DESC;

----------------------------------------------------------------------
-- 22. COLLECTION STORES — specimen count per store (project_record_record),
--     with the storage hierarchy.
----------------------------------------------------------------------
SELECT st.data ->> 'building' AS building,
       st.data ->> 'room'     AS room,
       st.data ->> 'cabinet'  AS cabinet,
       count(*) AS specimens
FROM dbnext.project_record_record rr
JOIN dbnext.keyword k ON k.id = rr.id_keyword AND k.name = 'stored in'
JOIN dbnext.project_record st ON st.id = rr.id_project_record_2
GROUP BY 1, 2, 3
ORDER BY specimens DESC;

----------------------------------------------------------------------
-- 23. FULL PROVENANCE — for a sample of specimens, join taxon (preferred
--     determination), locality (parent) and store (peer link) together.
----------------------------------------------------------------------
SELECT pr.id AS specimen,
       i.name AS taxon,
       loc.data ->> 'locality' AS collected_at,
       st.data  ->> 'cabinet'  AS stored_in
FROM dbnext.project_record pr
JOIN dbnext.project_record_project prp ON prp.id_project_record = pr.id AND prp.id_project IN (8,9,10)
LEFT JOIN dbnext.project_record_determination d ON d.id_project_record = pr.id AND d.preferred
LEFT JOIN dbnext.item_list_item ili ON ili.id = d.id_item_list_item
LEFT JOIN dbnext.item i ON i.id = ili.id_item
LEFT JOIN dbnext.project_record_parent pp ON pp.id_project_record = pr.id
     AND pp.id_keyword = (SELECT id FROM dbnext.keyword WHERE name='collected at' AND id_parent IS NOT NULL)
LEFT JOIN dbnext.project_record loc ON loc.id = pp.id_project_record_parent
LEFT JOIN dbnext.project_record_record rr ON rr.id_project_record_1 = pr.id
     AND rr.id_keyword = (SELECT id FROM dbnext.keyword WHERE name='stored in' AND id_parent IS NOT NULL)
LEFT JOIN dbnext.project_record st ON st.id = rr.id_project_record_2
ORDER BY pr.id
LIMIT 15;

----------------------------------------------------------------------
-- 24. TAXON BRANCH/RANK — lineage denormalised into item.data by
--     seed_taxon_branch.sql. Find all taxa in family Felidae using the
--     rank-keyed classification object (GIN jsonb containment), and show
--     each item's own rank + full ranked path.
----------------------------------------------------------------------
SELECT data ->> 'rank' AS rank,
       name,
       data ->> 'branch_path' AS branch_path
FROM dbnext.item
WHERE data @> '{"classification":{"family":"Felidae"}}'::jsonb
ORDER BY data ->> 'rank_depth', name;
