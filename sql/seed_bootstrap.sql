--
-- seed_bootstrap.sql — base scaffold that the demo seeds assume already exists
--
-- The other seed scripts reference, by fixed id, a small amount of pre-existing
-- data. On a fresh (schema-only) database those rows are absent, so run THIS
-- first. It creates, with the exact ids the seeds expect:
--   * user 13            — "Armand Turpel" (created_by / authority user)
--   * keyword 40         — "Domain" root, with children 42/43/44/45
--   * projects 7..10     — the four domain projects
--
-- Idempotent: ON CONFLICT (id) DO NOTHING, so it is a no-op if the scaffold is
-- already present (e.g. on the original dbnext3). Identity sequences are then
-- advanced so later auto-generated ids do not collide with these explicit ones.
--
-- Prerequisites (NOT created here): the dbnext schema itself plus the PostGIS
-- and pg_trgm extensions. See the run-order notes at the bottom of this file.
--

BEGIN;

INSERT INTO dbnext.users (id, name) VALUES
    (13, 'Armand Turpel')
    ON CONFLICT (id) DO NOTHING;

INSERT INTO dbnext.keyword (id, id_parent, name, description) VALUES
    (40, NULL, 'Domain', 'top-level subject domains'),
    (42, 40,  'Life Science Observations', NULL),
    (43, 40,  'Life Science Collections',  NULL),
    (44, 40,  'Paleontology Collections',  NULL),
    (45, 40,  'Mineralogy Collections',    NULL)
    ON CONFLICT (id) DO NOTHING;

INSERT INTO dbnext.project (id, name) VALUES
    (7,  'Life Science Observations'),
    (8,  'Life Science Collections'),
    (9,  'Paleontology Collections'),
    (10, 'Mineralogy Collections')
    ON CONFLICT (id) DO NOTHING;

-- advance identity sequences past the explicit ids inserted above
SELECT setval('dbnext.users_id_seq',   GREATEST((SELECT max(id) FROM dbnext.users),   13));
SELECT setval('dbnext.keyword_id_seq', GREATEST((SELECT max(id) FROM dbnext.keyword), 45));
SELECT setval('dbnext.project_id_seq', GREATEST((SELECT max(id) FROM dbnext.project), 10));

COMMIT;

--
-- RUN ORDER on a fresh database (psql), with a connection like
--   postgresql://postgres:PASSWORD@localhost:5432/DBNAME
--
--   createdb DBNAME
--   psql -d DBNAME -f sql/db_schema.sql          -- schema + extensions *
--   psql -d DBNAME -f sql/seed_bootstrap.sql     -- this file (scaffold)
--   psql -d DBNAME -f sql/seed_test_data.sql     -- curated demo
--   psql -d DBNAME -f sql/seed_bulk_data.sql     -- 40000 bulk records
--   psql -d DBNAME -f sql/seed_relations_data.sql-- locations + stores links
--   psql -d DBNAME -f sql/seed_taxon_branch.sql  -- taxon lineage into item.data
--
-- * IMPORTANT: the seeds match the LIVE dbnext3 column layout, which has
--   diverged from the committed sql/db_schema.sql (e.g. data_definition.id_group
--   vs id_data_group, project_record_geometry.id_record vs id_project_record).
--   If db_schema.sql still differs from your live DB, build the schema by
--   dumping it from the working database instead:
--     pg_dump --schema-only --schema=dbnext SOURCEDB > sql/schema_live.sql
--   then load schema_live.sql in the step above.
--
