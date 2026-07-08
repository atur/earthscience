--
-- seed_taxon_branch.sql — denormalise each taxon's lineage (with RANK) into
-- item.data.
--
-- Run as the LAST seed step (after seed_test_data / seed_bulk_data /
-- seed_relations_data). Walks item_list_item.id_parent from the root down for
-- every taxonomy item_list (i.e. all lists except Locations / Collection
-- Stores) and stores, on each item's jsonb data:
--
--   data.rank          the item's own rank, e.g. "genus"
--   data.branch        ordered array of {rank,name}, root -> self, e.g.
--                      [{"rank":"kingdom","name":"Animalia"}, ...,
--                       {"rank":"species","name":"Panthera leo"}]
--   data.classification rank-keyed object, e.g.
--                      {"kingdom":"Animalia",...,"species":"Panthera leo"}
--   data.branch_path   "Animalia > ... > Panthera leo"
--   data.rank_depth    number of levels (1 = root)
--
-- Ranks come from an explicit per-list depth->rank map (rankmap below) because
-- the curated lists deliberately skip ranks (e.g. Vascular Plants goes
-- kingdom > family > genus > species). Existing data keys (period,
-- chemical_formula, ...) are preserved; this is idempotent and re-runnable.
--

BEGIN;

WITH RECURSIVE
rankmap(list_name, depth, rank) AS (VALUES
    -- full Linnaean taxonomies (bulk)
    ('Animalia - full taxonomy',1,'kingdom'),('Animalia - full taxonomy',2,'phylum'),
    ('Animalia - full taxonomy',3,'class'),('Animalia - full taxonomy',4,'order'),
    ('Animalia - full taxonomy',5,'family'),('Animalia - full taxonomy',6,'genus'),
    ('Animalia - full taxonomy',7,'species'),
    ('Plantae - full taxonomy',1,'kingdom'),('Plantae - full taxonomy',2,'phylum'),
    ('Plantae - full taxonomy',3,'class'),('Plantae - full taxonomy',4,'order'),
    ('Plantae - full taxonomy',5,'family'),('Plantae - full taxonomy',6,'genus'),
    ('Plantae - full taxonomy',7,'species'),
    ('Fossil taxa - full taxonomy',1,'kingdom'),('Fossil taxa - full taxonomy',2,'phylum'),
    ('Fossil taxa - full taxonomy',3,'class'),('Fossil taxa - full taxonomy',4,'order'),
    ('Fossil taxa - full taxonomy',5,'family'),('Fossil taxa - full taxonomy',6,'genus'),
    ('Fossil taxa - full taxonomy',7,'species'),
    ('Mineral systematics',1,'class'),('Mineral systematics',2,'species'),
    -- curated demo lists (skip ranks)
    ('Birds of Central Europe',1,'class'),('Birds of Central Europe',2,'order'),
    ('Birds of Central Europe',3,'family'),('Birds of Central Europe',4,'genus'),
    ('Birds of Central Europe',5,'species'),
    ('Vascular Plants',1,'kingdom'),('Vascular Plants',2,'family'),
    ('Vascular Plants',3,'genus'),('Vascular Plants',4,'species'),
    ('Fossil Taxa',1,'class'),('Fossil Taxa',2,'genus'),('Fossil Taxa',3,'species'),
    ('Mineral Species',1,'species')
),
chain AS (
    SELECT ili.id, ili.id_item, 1 AS depth,
           rm.rank AS own_rank,
           jsonb_build_array(jsonb_build_object('rank', rm.rank, 'name', i.name)) AS branch,
           jsonb_build_object(coalesce(rm.rank,'rank1'), i.name) AS classification,
           i.name::text AS path
    FROM dbnext.item_list_item ili
    JOIN dbnext.item i ON i.id = ili.id_item
    JOIN dbnext.item_list l ON l.id = ili.id_item_list
    LEFT JOIN rankmap rm ON rm.list_name = l.name AND rm.depth = 1
    WHERE ili.id_parent IS NULL
      AND l.name NOT IN ('Locations','Collection Stores')
    UNION ALL
    SELECT c.id, c.id_item, chain.depth + 1,
           rm.rank,
           chain.branch || jsonb_build_object('rank', rm.rank, 'name', ci.name),
           chain.classification || jsonb_build_object(coalesce(rm.rank,'rank'||(chain.depth+1)), ci.name),
           chain.path || ' > ' || ci.name
    FROM chain
    JOIN dbnext.item_list_item c ON c.id_parent = chain.id
    JOIN dbnext.item ci ON ci.id = c.id_item
    JOIN dbnext.item_list l ON l.id = c.id_item_list
    LEFT JOIN rankmap rm ON rm.list_name = l.name AND rm.depth = chain.depth + 1
)
UPDATE dbnext.item it
SET data = it.data || jsonb_build_object(
        'rank',           chain.own_rank,
        'branch',         chain.branch,
        'classification', chain.classification,
        'branch_path',    chain.path,
        'rank_depth',     chain.depth)
FROM chain
WHERE it.id = chain.id_item;

COMMIT;
