--
-- curator_queries.sql — practical day-to-day SELECTs for collection curators
--
-- Grouped by role:
--   A. Everyday lookups & collection management (all curators)
--   B. Life-science curator (observations + collections)
--   C. Paleontology curator
--   D. Mineralogy curator
--   E. Curation / data-quality backlog
--
-- All queries are read-only. Values in WHERE clauses (catalog numbers, taxon
-- names, places, dates) are EXAMPLES — edit them for your case. In pgAdmin,
-- put the cursor in one statement and press F5 to run just that one.
--
-- Relies on the demo seed (seed_test_data + seed_bulk_data +
-- seed_relations_data + seed_taxon_branch).
--

----------------------------------------------------------------------------
-- A. EVERYDAY LOOKUPS & COLLECTION MANAGEMENT
----------------------------------------------------------------------------

-- A1. Find a specimen by ANY identifier (catalog no., accession, barcode...).
--     Partial match supported. Change the search string.
SELECT pri.value AS identifier, kt.name AS id_type,
       pr.id AS record, p.name AS collection
FROM dbnext.project_record_identifier pri
JOIN dbnext.keyword kt ON kt.id = pri.id_keyword
JOIN dbnext.project_record pr ON pr.id = pri.id_project_record
JOIN dbnext.project_record_project prp ON prp.id_project_record = pr.id
JOIN dbnext.project p ON p.id = prp.id_project
WHERE pri.value ILIKE '%HERB-2001%'
ORDER BY pri.value;

-- A2. Full dossier for one specimen (by catalog number): taxon + lineage,
--     collector, locality, storage, all identifiers, dates.
SELECT pr.id AS record,
       i.name AS taxon,
       det.data ->> 'rank' AS taxon_rank,
       det.data ->> 'branch_path' AS lineage,
       coalesce(u.name, d.determined_by_name) AS determined_by,
       loc.data ->> 'locality' AS collected_at,
       st.data  ->> 'cabinet'  AS stored_in,
       pr.date_start, pr.date_end,
       (SELECT string_agg(kt.name || ': ' || x.value, '; ')
          FROM dbnext.project_record_identifier x
          JOIN dbnext.keyword kt ON kt.id = x.id_keyword
         WHERE x.id_project_record = pr.id) AS identifiers
FROM dbnext.project_record_identifier pid
JOIN dbnext.project_record pr ON pr.id = pid.id_project_record
LEFT JOIN dbnext.project_record_determination d ON d.id_project_record = pr.id AND d.preferred
LEFT JOIN dbnext.item_list_item ili ON ili.id = d.id_item_list_item
LEFT JOIN dbnext.item i   ON i.id = ili.id_item
LEFT JOIN dbnext.item det ON det.id = ili.id_item      -- same item, for data
LEFT JOIN dbnext.users u ON u.id = d.determined_by
LEFT JOIN dbnext.project_record_parent pp ON pp.id_project_record = pr.id
     AND pp.id_keyword = (SELECT id FROM dbnext.keyword WHERE name='collected at' AND id_parent IS NOT NULL)
LEFT JOIN dbnext.project_record loc ON loc.id = pp.id_project_record_parent
LEFT JOIN dbnext.project_record_record rr ON rr.id_project_record_1 = pr.id
     AND rr.id_keyword = (SELECT id FROM dbnext.keyword WHERE name='stored in' AND id_parent IS NOT NULL)
LEFT JOIN dbnext.project_record st ON st.id = rr.id_project_record_2
WHERE pid.value = 'HERB-2001';

-- A3. Recently catalogued (last 30 days) across all collections.
SELECT pr.id, p.name AS collection, dom.name AS domain, pr.date_create
FROM dbnext.project_record pr
JOIN dbnext.project_record_project prp ON prp.id_project_record = pr.id
JOIN dbnext.project p ON p.id = prp.id_project
LEFT JOIN dbnext.project_record_keyword prk ON prk.id_project_record = pr.id
LEFT JOIN dbnext.keyword dom ON dom.id = prk.id_keyword AND dom.id_parent = 40
WHERE pr.date_create >= now() - interval '30 days'
ORDER BY pr.date_create DESC
LIMIT 100;

-- A4. Recently MODIFIED records (audit / review what changed).
SELECT pr.id, pr.date_modify, pr.modified_by, p.name AS collection
FROM dbnext.project_record pr
JOIN dbnext.project_record_project prp ON prp.id_project_record = pr.id
JOIN dbnext.project p ON p.id = prp.id_project
WHERE pr.date_modify > pr.date_create
ORDER BY pr.date_modify DESC
LIMIT 50;

-- A5. "Where is it stored?" — locate a specimen by catalog number.
SELECT pid.value AS catalog_no,
       st.data ->> 'building' AS building,
       st.data ->> 'room'     AS room,
       st.data ->> 'cabinet'  AS cabinet
FROM dbnext.project_record_identifier pid
JOIN dbnext.project_record_record rr ON rr.id_project_record_1 = pid.id_project_record
JOIN dbnext.keyword k ON k.id = rr.id_keyword AND k.name = 'stored in'
JOIN dbnext.project_record st ON st.id = rr.id_project_record_2
WHERE pid.value = 'MIN-1001';

-- A6. "What's in this cabinet?" — list everything in a storage unit.
SELECT i.name AS taxon, count(*) AS specimens
FROM dbnext.project_record st
JOIN dbnext.project_record_record rr ON rr.id_project_record_2 = st.id
JOIN dbnext.keyword k ON k.id = rr.id_keyword AND k.name = 'stored in'
JOIN dbnext.project_record_determination d ON d.id_project_record = rr.id_project_record_1 AND d.preferred
JOIN dbnext.item_list_item ili ON ili.id = d.id_item_list_item
JOIN dbnext.item i ON i.id = ili.id_item
WHERE st.data ->> 'cabinet' = 'Fossil Drawer P1'
GROUP BY i.name
ORDER BY specimens DESC, taxon;

----------------------------------------------------------------------------
-- B. LIFE-SCIENCE CURATOR
----------------------------------------------------------------------------

-- B1. Species checklist for a collection (distinct taxa + holdings count).
SELECT i.name AS species, i.data ->> 'branch_path' AS lineage, count(*) AS records
FROM dbnext.project_record_project prp
JOIN dbnext.project_record_determination d ON d.id_project_record = prp.id_project_record AND d.preferred
JOIN dbnext.item_list_item ili ON ili.id = d.id_item_list_item
JOIN dbnext.item i ON i.id = ili.id_item
WHERE prp.id_project = 8                       -- Life Science Collections
  AND i.data ->> 'rank' = 'species'
GROUP BY i.name, i.data ->> 'branch_path'
ORDER BY records DESC, species
LIMIT 50;

-- B2. All specimens of a family or genus (uses the rank-keyed classification).
--     Change 'Fagaceae' / the rank key as needed.
SELECT pr.id AS record, i.name AS taxon, p.name AS collection
FROM dbnext.item i
JOIN dbnext.item_list_item ili ON ili.id_item = i.id
JOIN dbnext.project_record_determination d ON d.id_item_list_item = ili.id AND d.preferred
JOIN dbnext.project_record pr ON pr.id = d.id_project_record
JOIN dbnext.project_record_project prp ON prp.id_project_record = pr.id
JOIN dbnext.project p ON p.id = prp.id_project
WHERE i.data @> '{"classification":{"family":"Fagaceae"}}'::jsonb
ORDER BY taxon, record;

-- B3. Observations of a genus over time (phenology by year & month).
SELECT extract(year  FROM pr.date_start)::int AS yr,
       extract(month FROM pr.date_start)::int AS mon,
       count(*) AS observations
FROM dbnext.project_record_project prp
JOIN dbnext.project_record pr ON pr.id = prp.id_project_record
JOIN dbnext.project_record_determination d ON d.id_project_record = pr.id AND d.preferred
JOIN dbnext.item_list_item ili ON ili.id = d.id_item_list_item
JOIN dbnext.item i ON i.id = ili.id_item
WHERE prp.id_project = 7                        -- Observations
  AND i.data @> '{"classification":{"genus":"Parus"}}'::jsonb
  AND pr.date_start IS NOT NULL
GROUP BY yr, mon
ORDER BY yr, mon;

-- B4. Everything collected/observed by a given person.
SELECT u.name AS person, kr.name AS role, count(*) AS records
FROM dbnext.project_record_user pru
JOIN dbnext.users u ON u.id = pru.id_user
LEFT JOIN dbnext.project_record_user_keyword puk ON puk.id_project_record_user = pru.id
LEFT JOIN dbnext.keyword kr ON kr.id = puk.id_keyword
WHERE u.name = 'Maria Hofer'
GROUP BY u.name, kr.name
ORDER BY records DESC;

-- B5. Threatened taxa held (anything not "least concern").
SELECT cs.name AS conservation_status, i.name AS taxon, count(*) AS records
FROM dbnext.project_record_keyword prk
JOIN dbnext.keyword cs ON cs.id = prk.id_keyword
JOIN dbnext.keyword csp ON csp.id = cs.id_parent AND csp.name = 'Conservation Status'
JOIN dbnext.project_record_determination d ON d.id_project_record = prk.id_project_record AND d.preferred
JOIN dbnext.item_list_item ili ON ili.id = d.id_item_list_item
JOIN dbnext.item i ON i.id = ili.id_item
WHERE cs.name <> 'least concern'
GROUP BY cs.name, i.name
ORDER BY records DESC
LIMIT 50;

-- B6. Records within 100 km of a point (here: Munich). PostGIS radius search.
SELECT pr.id, i.name AS taxon,
       round((public.ST_Distance(g.geom::geography,
              public.ST_SetSRID(public.ST_MakePoint(11.58,48.14),4326)::geography)/1000)::numeric,1) AS km
FROM dbnext.project_record_geometry g
JOIN dbnext.project_record pr ON pr.id = g.id_project_record
LEFT JOIN dbnext.project_record_determination d ON d.id_project_record = pr.id AND d.preferred
LEFT JOIN dbnext.item_list_item ili ON ili.id = d.id_item_list_item
LEFT JOIN dbnext.item i ON i.id = ili.id_item
WHERE public.ST_DWithin(g.geom::geography,
        public.ST_SetSRID(public.ST_MakePoint(11.58,48.14),4326)::geography, 100000)
ORDER BY km
LIMIT 100;

----------------------------------------------------------------------------
-- C. PALEONTOLOGY CURATOR
----------------------------------------------------------------------------

-- C1. Holdings by geological period.
SELECT pr.data ->> 'period' AS period, count(*) AS specimens
FROM dbnext.project_record_project prp
JOIN dbnext.project_record pr ON pr.id = prp.id_project_record
WHERE prp.id_project = 9
GROUP BY pr.data ->> 'period'
ORDER BY specimens DESC;

-- C2. Fossils from a given formation.
SELECT pr.id, i.name AS taxon, pr.data ->> 'period' AS period
FROM dbnext.project_record pr
JOIN dbnext.project_record_project prp ON prp.id_project_record = pr.id AND prp.id_project = 9
LEFT JOIN dbnext.project_record_determination d ON d.id_project_record = pr.id AND d.preferred
LEFT JOIN dbnext.item_list_item ili ON ili.id = d.id_item_list_item
LEFT JOIN dbnext.item i ON i.id = ili.id_item
WHERE pr.data ->> 'formation' = 'Whitby Mudstone'
ORDER BY taxon
LIMIT 100;

-- C3. Taxonomic breakdown by class (trilobites, ammonites, dinosaurs...).
SELECT i.data -> 'classification' ->> 'class' AS class, count(*) AS specimens
FROM dbnext.project_record_project prp
JOIN dbnext.project_record_determination d ON d.id_project_record = prp.id_project_record AND d.preferred
JOIN dbnext.item_list_item ili ON ili.id = d.id_item_list_item
JOIN dbnext.item i ON i.id = ili.id_item
WHERE prp.id_project = 9
GROUP BY 1
ORDER BY specimens DESC;

-- C4. Type specimens (holotype / paratype / syntype) across collections.
SELECT ts.name AS type_status, pr.id AS record, i.name AS taxon,
       (SELECT value FROM dbnext.project_record_identifier x
         WHERE x.id_project_record = pr.id LIMIT 1) AS identifier
FROM dbnext.project_record_keyword prk
JOIN dbnext.keyword ts ON ts.id = prk.id_keyword
JOIN dbnext.keyword tsp ON tsp.id = ts.id_parent AND tsp.name = 'Specimen Type Status'
JOIN dbnext.project_record pr ON pr.id = prk.id_project_record
LEFT JOIN dbnext.project_record_determination d ON d.id_project_record = pr.id AND d.preferred
LEFT JOIN dbnext.item_list_item ili ON ili.id = d.id_item_list_item
LEFT JOIN dbnext.item i ON i.id = ili.id_item
WHERE ts.name IN ('holotype','paratype','syntype')
ORDER BY type_status, taxon;

-- C5. Period x class matrix (how many specimens of each class per period).
SELECT pr.data ->> 'period' AS period,
       i.data -> 'classification' ->> 'class' AS class,
       count(*) AS n
FROM dbnext.project_record_project prp
JOIN dbnext.project_record pr ON pr.id = prp.id_project_record AND prp.id_project = 9
JOIN dbnext.project_record_determination d ON d.id_project_record = pr.id AND d.preferred
JOIN dbnext.item_list_item ili ON ili.id = d.id_item_list_item
JOIN dbnext.item i ON i.id = ili.id_item
GROUP BY 1, 2
ORDER BY period, n DESC;

----------------------------------------------------------------------------
-- D. MINERALOGY CURATOR
----------------------------------------------------------------------------

-- D1. Inventory by mineral class.
SELECT i.data -> 'classification' ->> 'class' AS mineral_class, count(*) AS specimens
FROM dbnext.project_record_project prp
JOIN dbnext.project_record_determination d ON d.id_project_record = prp.id_project_record AND d.preferred
JOIN dbnext.item_list_item ili ON ili.id = d.id_item_list_item
JOIN dbnext.item i ON i.id = ili.id_item
WHERE prp.id_project = 10
GROUP BY 1
ORDER BY specimens DESC;

-- D2. Search by crystal system (and show hardness/formula).
SELECT pr.id, i.name AS mineral,
       pr.data ->> 'crystal_system' AS crystal_system,
       pr.data ->> 'mohs_hardness'  AS mohs,
       pr.data ->> 'chemical_formula' AS formula
FROM dbnext.project_record pr
JOIN dbnext.project_record_project prp ON prp.id_project_record = pr.id AND prp.id_project = 10
LEFT JOIN dbnext.project_record_determination d ON d.id_project_record = pr.id AND d.preferred
LEFT JOIN dbnext.item_list_item ili ON ili.id = d.id_item_list_item
LEFT JOIN dbnext.item i ON i.id = ili.id_item
WHERE pr.data @> '{"crystal_system":"cubic"}'::jsonb
ORDER BY mineral
LIMIT 100;

-- D3. Hard minerals (Mohs >= 7) — extracts the leading number from the field.
SELECT DISTINCT i.name AS mineral, pr.data ->> 'mohs_hardness' AS mohs
FROM dbnext.project_record pr
JOIN dbnext.project_record_project prp ON prp.id_project_record = pr.id AND prp.id_project = 10
JOIN dbnext.project_record_determination d ON d.id_project_record = pr.id AND d.preferred
JOIN dbnext.item_list_item ili ON ili.id = d.id_item_list_item
JOIN dbnext.item i ON i.id = ili.id_item
WHERE nullif(regexp_replace(pr.data ->> 'mohs_hardness', '[^0-9.].*$', ''), '')::numeric >= 7
ORDER BY mineral;

-- D4. Find minerals containing an element in the chemical formula (e.g. Cu).
SELECT DISTINCT i.name AS mineral, pr.data ->> 'chemical_formula' AS formula
FROM dbnext.project_record pr
JOIN dbnext.project_record_project prp ON prp.id_project_record = pr.id AND prp.id_project = 10
JOIN dbnext.project_record_determination d ON d.id_project_record = pr.id AND d.preferred
JOIN dbnext.item_list_item ili ON ili.id = d.id_item_list_item
JOIN dbnext.item i ON i.id = ili.id_item
WHERE pr.data ->> 'chemical_formula' LIKE '%Cu%'
ORDER BY mineral;

-- D5. Top mineral species by number of specimens held.
SELECT i.name AS mineral, count(*) AS specimens
FROM dbnext.project_record_project prp
JOIN dbnext.project_record_determination d ON d.id_project_record = prp.id_project_record AND d.preferred
JOIN dbnext.item_list_item ili ON ili.id = d.id_item_list_item
JOIN dbnext.item i ON i.id = ili.id_item
WHERE prp.id_project = 10
GROUP BY i.name
ORDER BY specimens DESC, mineral
LIMIT 20;

----------------------------------------------------------------------------
-- E. CURATION / DATA-QUALITY BACKLOG
----------------------------------------------------------------------------

-- E1. Records with NO preferred determination (need identifying).
SELECT pr.id, p.name AS collection, pr.date_create
FROM dbnext.project_record pr
JOIN dbnext.project_record_project prp ON prp.id_project_record = pr.id
JOIN dbnext.project p ON p.id = prp.id_project
WHERE prp.id_project IN (7,8,9,10)
  AND NOT EXISTS (SELECT 1 FROM dbnext.project_record_determination d
                  WHERE d.id_project_record = pr.id AND d.preferred)
ORDER BY pr.id
LIMIT 100;

-- E2. Records with NO geometry (georeferencing backlog).
SELECT pr.id, p.name AS collection
FROM dbnext.project_record pr
JOIN dbnext.project_record_project prp ON prp.id_project_record = pr.id
JOIN dbnext.project p ON p.id = prp.id_project
WHERE prp.id_project IN (7,8,9,10)
  AND NOT EXISTS (SELECT 1 FROM dbnext.project_record_geometry g WHERE g.id_project_record = pr.id)
ORDER BY pr.id
LIMIT 100;

-- E3. Collection specimens (8,9,10) NOT assigned to a storage unit.
SELECT pr.id, p.name AS collection
FROM dbnext.project_record pr
JOIN dbnext.project_record_project prp ON prp.id_project_record = pr.id
JOIN dbnext.project p ON p.id = prp.id_project
WHERE prp.id_project IN (8,9,10)
  AND NOT EXISTS (
      SELECT 1 FROM dbnext.project_record_record rr
      JOIN dbnext.keyword k ON k.id = rr.id_keyword AND k.name = 'stored in'
      WHERE rr.id_project_record_1 = pr.id)
ORDER BY pr.id
LIMIT 100;

-- E4. Determinations made by a historical determiner (free text, no user
--     account) — candidates to reconcile against the user list.
SELECT d.determined_by_name, count(*) AS determinations
FROM dbnext.project_record_determination d
WHERE d.determined_by_name IS NOT NULL AND d.determined_by IS NULL
GROUP BY d.determined_by_name
ORDER BY determinations DESC;

-- E5. Duplicate catalog numbers within a type (data-integrity check; should
--     normally return no rows).
SELECT kt.name AS id_type, pri.value, count(*) AS times_used
FROM dbnext.project_record_identifier pri
JOIN dbnext.keyword kt ON kt.id = pri.id_keyword
GROUP BY kt.name, pri.value
HAVING count(*) > 1
ORDER BY times_used DESC;

-- E6. Coverage dashboard: per collection, % of records with a determination,
--     a geometry and (for collections) a storage assignment.
SELECT p.name AS collection,
       count(*) AS records,
       round(100.0 * count(*) FILTER (WHERE EXISTS (
           SELECT 1 FROM dbnext.project_record_determination d
           WHERE d.id_project_record = pr.id AND d.preferred)) / count(*), 1) AS pct_determined,
       round(100.0 * count(*) FILTER (WHERE EXISTS (
           SELECT 1 FROM dbnext.project_record_geometry g
           WHERE g.id_project_record = pr.id)) / count(*), 1) AS pct_georeferenced
FROM dbnext.project_record pr
JOIN dbnext.project_record_project prp ON prp.id_project_record = pr.id
JOIN dbnext.project p ON p.id = prp.id_project
WHERE prp.id_project IN (7,8,9,10)
GROUP BY p.name
ORDER BY collection;
