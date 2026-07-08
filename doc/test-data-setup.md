# Test data setup

How to load the demo / test dataset for the `dbnext` museum schema:
realistic records across four domains (life-science observations,
life-science collections, paleontology, mineralogy) plus locations,
collection stores and full taxon hierarchies.

All scripts live in `sql/`, are schema-qualified (`dbnext.`), wrap
themselves in a transaction, and are idempotent (re-running is a no-op
or recomputes the same result).

## What you get

After a full load:

| Entity                         | Count |
|--------------------------------|------:|
| project_record (total)         | 40055 |
| - domain records (proj 7-10)   | 40019 |
| - localities (proj "Locations")|    26 |
| - stores (proj "Stores")       |    10 |
| item (taxa + places + stores)  |   517 |
| items with `data.branch`       |   458 |
| location parent links          | 40017 |
| store ("stored in") links      | 30015 |

Domain records split ~10000 per project (7,8,9,10). Every taxonomy item
carries its lineage in `item.data` (`branch`, `classification`, `rank`,
`branch_path`, `rank_depth`).

## Prerequisites

Two things must be in place before the seeds will run on an **empty**
database:

1. **Schema + extensions.** The schema needs the `dbnext` namespace and
   the PostGIS and pg_trgm extensions (the role running it needs
   superuser to create extensions).

   > IMPORTANT: the seeds target the LIVE database layout, which has
   > diverged from the committed `sql/db_schema.sql` (e.g.
   > `data_definition.id_group` vs `id_data_group`,
   > `project_record_geometry.id_record` vs `id_project_record`). If your
   > `db_schema.sql` still differs from the working DB, build the schema
   > by dumping the working DB instead:
   >
   > ```
   > pg_dump --schema-only --schema=dbnext SOURCEDB > sql/schema_live.sql
   > ```

2. **Base scaffold.** The seeds reference, by fixed id, rows that they do
   not create: user `13`, projects `7..10`, and the `Domain` keyword tree
   `40 -> 42/43/44/45`. `sql/seed_bootstrap.sql` inserts exactly those
   (idempotent) and advances the identity sequences.

## File inventory

| File                          | Purpose                              |
|-------------------------------|--------------------------------------|
| `seed_bootstrap.sql`          | base scaffold (user, projects, domains) |
| `seed_test_data.sql`          | curated demo: 19 records, taxonomies, full keyword vocabulary |
| `seed_bulk_data.sql`          | 40000 bulk records + full Kingdom->Species taxonomies |
| `seed_relations_data.sql`     | locations + collection stores as records, linked to domain records |
| `seed_taxon_branch.sql`       | denormalises taxon lineage + rank into `item.data` |
| `seed_bulk_teardown.sql`      | removes the bulk data only           |
| `seed_relations_teardown.sql` | removes locations / stores / links   |
| `test_queries.sql`            | validation queries (feature coverage)|
| `curator_queries.sql`         | day-to-day queries by curator role   |
| `test_cascade_deletion.sql`   | cascade + trigger self-test (rolls back) |

## Run order (fresh database)

Using a connection like
`postgresql://postgres:PASSWORD@localhost:5432/DBNAME`:

```
createdb DBNAME
psql -d DBNAME -f sql/db_schema.sql             # or schema_live.sql (see note)
psql -d DBNAME -f sql/seed_bootstrap.sql
psql -d DBNAME -f sql/seed_test_data.sql
psql -d DBNAME -f sql/seed_bulk_data.sql
psql -d DBNAME -f sql/seed_relations_data.sql
psql -d DBNAME -f sql/seed_taxon_branch.sql
```

`seed_taxon_branch.sql` must run last (it reads the taxonomies the other
seeds build). `seed_relations_data.sql` should run after the bulk seed so
the location/store links cover the full dataset.

### pgAdmin

Each file has no psql meta-commands, so you can open it in the Query
Tool and press F5. Run the files in the same order.

## Transaction discipline

`project_record` has a deferred constraint trigger
(`trg_project_record_requires_project`) requiring every record to have at
least one `project_record_project` by COMMIT. Each seed already does this
inside one transaction, so just run each file whole — do not execute
individual INSERTs in autocommit mode.

## Reset / re-seed

To remove the large datasets and reload them:

```
psql -d DBNAME -f sql/seed_relations_teardown.sql
psql -d DBNAME -f sql/seed_bulk_teardown.sql
psql -d DBNAME -f sql/seed_bulk_data.sql
psql -d DBNAME -f sql/seed_relations_data.sql
psql -d DBNAME -f sql/seed_taxon_branch.sql
```

The curated seed (`seed_test_data.sql`) has no teardown; it is the small
base set. To drop everything, drop and recreate the database.

## Querying the data

- `sql/test_queries.sql` — demonstrates each schema feature (PostGIS
  spatial, temporal `tstzrange`, jsonb containment, pg_trgm fuzzy search,
  taxonomy recursion, keyword classification, relationships, taxon
  branch).
- `sql/curator_queries.sql` — practical daily queries grouped by role
  (everyday lookups, life-science, paleontology, mineralogy, and a
  data-quality / curation backlog section). Values in `WHERE` clauses are
  examples to edit.
