# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working
with code in this repository.

## What this project is

A PostgreSQL schema (single namespace `dbnext`) for managing museum
natural-science collections and life-science observations. The repository
currently contains only the schema dump — there is no application code,
migration tool, build system, or test suite in place. New work will
typically be either (a) modifying `sql/db_schema.sql`, or (b) building
tooling/applications on top of this schema.

The schema was produced by `pg_dump` from PostgreSQL 18.1 and uses fully
schema-qualified names
(`SELECT pg_catalog.set_config('search_path', '', false)`). Preserve the
`dbnext.` qualification in any new SQL.

## Required PostgreSQL extensions

The schema file creates these in `public`:

- **PostGIS** — `project_record_geometry.geom` is
  `public.geometry(Geometry, 4326)`, with GiST index `idx_prg_geom`.
- **pg_trgm** — `idx_item_name_trgm` uses `public.gin_trgm_ops` for fuzzy
  matching on `item.name`.

The schema includes `CREATE SCHEMA IF NOT EXISTS dbnext` and
`CREATE EXTENSION IF NOT EXISTS` for both extensions, so a fresh install is
one step (the role running psql needs superuser to create extensions):

```
createdb dbnext
psql -d dbnext -f sql/db_schema.sql
```

## Conceptual architecture

The schema separates **what is recorded** (`item` / `item_list`) from
**the act of recording** (`project_record`), with a generic custom-fields
system (`data_definition` / `data_group`) and a typed-tag system
(`keyword`) layered across most entities.

### 1. Subjects: `item`, `item_list`, `item_list_item`

- `item` — a subject that can be recorded (e.g. a taxon name). Multilingual
  (`language text`, checked against `^[a-z]{2}$`), with a jsonb `data`
  column for custom fields.
- `item_list` — a curated list of items (a checklist, a taxonomy, etc.).
  Hierarchical via `id_parent`. Holds **two** data-group references:
  `item_list_id_data_group` (custom fields on the list itself) and
  `item_list_item_id_data_group` (custom fields on items *within this
  list*). The same `item` can have different custom-field schemas in
  different lists.
- `item_list_item` — the M:N join. Critically, this is also where the
  **list-internal hierarchy** lives:
  - `id_parent` → self-FK; e.g. taxonomic tree position *within this list*.
  - `id_identity` → groups synonymous entries.
  - `id_accepted` → points to the accepted entry.
  - All three are composite FKs `(col, id_item_list)` onto
    `UNIQUE (id, id_item_list)`, so they can only reference entries of the
    **same list**. They are `DEFERRABLE` (initially immediate): to move an
    entry to another list, defer them (`SET CONSTRAINTS ... DEFERRED`),
    update `id_item_list`, and fix
    `id_parent`/`id_identity`/`id_accepted` before commit.
  - Same `item` can appear in many lists with different parents/synonymy.
  - `data` — list-specific custom-field values for this item in this list
    (allowed fields via the list's `item_list_item_id_data_group`).
    Additive only:
    keys must not overlap with the item's global fields in `item.data`
    (application-enforced, not by the DB). Effective values of an item in
    a list = `item.data || item_list_item.data`.

### 2. Records: `project`, `project_record`

- `project` — organizational container; `id_user` is the single
  "authority" for the project.
- `project_record` — **the central table**: a specimen or observation.
  Holds a jsonb `data` blob, plus `date_start`/`date_end` and a *generated*
  `date_range tstzrange` (with GiST index) for temporal range queries
  (`@>`, `&&`).
- `project_record_project` (M:N): a record can belong to multiple
  projects. Two integrity rules enforce that records always have at least
  one project:
  - Constraint trigger `trg_prevent_last_project_association_delete`
    (AFTER DELETE OR UPDATE OF id_project_record, DEFERRABLE INITIALLY
    DEFERRED) blocks removing the last association at commit time —
    whether by DELETE or by re-pointing the row via UPDATE. It
    short-circuits when the parent `project_record` was itself deleted in
    the same transaction (so cascade deletes work).
    `trg_prevent_last_determination_delete` applies the same rule to
    `project_record_determination` (a record may start with zero
    determinations, but once it has any it cannot return to zero while it
    exists).
  - Deferred constraint trigger `trg_project_record_requires_project`
    (AFTER INSERT, deferrable) requires at least one association by
    transaction commit. **Insert into `project_record_project` in the same
    transaction**, or wrap in `BEGIN; ... COMMIT;` accordingly.
- `project_record_geometry` — PostGIS spatial geometry per record
  (one-to-many).
- `project_record_identifier` — multiple typed identifiers per record
  (catalog number, accession number, barcode, etc.); **the type is defined
  by `id_keyword`**, the value is free text.
- `project_record_parent` — vertical (parent/child) record relationships,
  optionally typed by keyword.
- `project_record_record` — horizontal (peer-to-peer) record
  relationships, **always** typed by keyword (e.g. "duplicate of",
  "host of", "same event").
- `project_record_determination` — taxonomic identifications linking
  record → `item_list_item`. Multiple per record; `preferred` flags the
  current accepted determination (at most one per record, enforced by a
  partial unique index). Carries `determined_by` (FK to user) and
  `determined_by_name` (free text for historical determiners not in the
  user table).
- `project_record_user` — people associated with a record (collectors,
  observers, etc.); their **role** is qualified by
  `project_record_user_keyword` (typed tags).

### 3. Custom fields: `data_definition` / `data_group`

A generic schema-on-data system. Many tables have a jsonb `data` column
(`item`, `item_list`, `item_list_item`, `keyword`, `media`, `project`,
`project_record`) and a sibling `id_data_group` (or two) pointing into
`data_group` — except `item_list_item.data`, whose allowed fields come
from the owning list's `item_list.item_list_item_id_data_group`. The
`data_group` resolves to a set of `data_definition` rows that describe the
allowed custom fields (name, type, validation regex, allowed values via
the `predefined_values` text array, rank for UI order).
`project_record_data_group` is many-to-many so a project can apply
multiple data groups to its records (ordered by `sort`). Despite the
name it links `project` — not `project_record` — to `data_group`:
records inherit the union of the data groups of their projects (via
`project_record_project`) and are never linked to a data group directly.

All `data` columns have GIN `jsonb_path_ops` indexes (with
`fastupdate=true`) — query custom fields with the `@>` containment
operator for index use.

### 4. Keywords: typed tags as a controlled vocabulary

`keyword` is hierarchical (`id_parent`), grouped under a `data_group` (so
keywords themselves can have custom fields), uniquely named per parent
(`uq_keyword_parent_name` uses `COALESCE(id_parent, 0)`).

Keywords serve **two distinct roles**, which is the most important pattern
to internalize:

- **As tags** via `*_keyword` link tables: `item_keyword`,
  `item_list_keyword`, `item_list_item_keyword`, `project_keyword`,
  `project_record_keyword`, `project_record_user_keyword`,
  `project_record_determination_keyword`, `users_keyword`.
- **As semantic typing** for relationships and slots:
  `project_record_record.id_keyword` (relationship type),
  `project_record_parent.id_keyword` (relationship type),
  `project_record_identifier.id_keyword` (identifier type),
  `project_record_determination.id_determination_method`, etc.

When adding a new typed slot, prefer "FK to keyword + companion data" over
inventing a new lookup table.

### 5. External identifiers and media

- `external_identifier` (source, identifier, url) is linked via
  `external_identifier_item` and `external_identifier_project_record`.
  Used for cross-referencing GBIF, BOLD, GenBank, Index Herbariorum, etc.
- `media` records (file_path is a path/URL — actual files live outside the
  DB) are linked via `media_item` and `project_record_media`.
- Deleting a `project_record` cascades to all 12 child/link tables
  (`project_record_determination`, `project_record_geometry`,
  `project_record_identifier`, `project_record_keyword`,
  `project_record_parent` (both directions), `project_record_project`,
  `project_record_record` (both directions), `project_record_user`,
  `external_identifier_project_record`, `project_record_media`) and onward
  through grandchildren (`project_record_determination_keyword`,
  `project_record_user_keyword`).

### 6. Users and audit

- `dbnext.users` (and the link table `dbnext.users_keyword`) holds
  Django-style auth fields (`password`, `last_login`, `is_active`,
  `is_staff`, `is_superuser`) — the schema is set up to play with a
  Django-like auth layer. The plural name avoids the `user` reserved word.
- Most domain tables carry `created_by` / `modified_by` (FKs to `users`)
  and `date_create` / `date_modify`. `date_create` defaults to `now()` on
  INSERT; `date_modify` is auto-stamped on UPDATE by trigger
  `trg_set_date_modify` (function `dbnext.set_date_modify`), unless the
  caller sets it explicitly. `modified_by` is **not** auto-maintained —
  application code must set it.

## Conventions to follow when extending the schema

- PKs are always `id bigint GENERATED BY DEFAULT AS IDENTITY` (explicit
  ids remain possible, e.g. for imports). The identity sequences keep the
  `<table>_id_seq` naming.
- FKs are named `id_<referenced_table>` (e.g. `id_project_record`).
  Disambiguating FKs to the same table use a suffix
  (`id_project_record_1`, `id_project_record_2`).
- Link tables follow `<a>_<b>` and almost always carry their own surrogate
  `id` plus a `UNIQUE (id_a, id_b)` constraint.
  - Deliberate exception: `project_record_data_group` is a *purpose*
    name, not a join name — it declares which data groups define
    `project_record.data`, scoped by project, so its FKs are
    `id_project` + `id_data_group`. Don't "fix" it to match the rule.
    A join written from the rule fails loudly (there is no
    `id_project_record` column), so it cannot silently join wrong.
- Add an FK index for every FK (`fki_*` or `idx_*`) — the schema does this
  consistently and PG won't auto-index FKs.
- For any new jsonb `data` column, use
  `jsonb DEFAULT '{}'::jsonb NOT NULL` and add a
  `GIN (data jsonb_path_ops) WITH (fastupdate=true)` index.
- A handful of FKs are intentionally `NOT VALID`
  (`fk_project_record_project_id_project_record`,
  `fk_project_record_user_keyword_project_record_user`, `fk_user`,
  `fk_user_keyword`) because historical rows may violate them. New inserts
  are still validated. Don't `VALIDATE CONSTRAINT` these without a
  data-cleanup pass.
- Comments (`COMMENT ON TABLE/COLUMN`) are the primary documentation
  surface — when you add tables/columns, add comments explaining intent,
  especially for relationships whose semantics aren't obvious from the
  column name.

## documentation

When writing documentation md files always try to get a line no longer
than 80 chars. Except tables.

## Behavioral guidelines to reduce common LLM coding mistakes.

Merge with project-specific instructions as needed.

Tradeoff: These guidelines bias toward caution over speed. For trivial
tasks, use judgment.

### Think Before Coding

Don't assume. Don't hide confusion. Surface tradeoffs.

Before implementing:

	1. State your assumptions explicitly. If uncertain, ask.
    2. If multiple interpretations exist, present them - don't pick silently.
    3. If a simpler approach exists, say so. Push back when warranted.
    4. If something is unclear, stop. Name what's confusing. Ask.

### Simplicity First

Minimum code that solves the problem. Nothing speculative.

    1. No features beyond what was asked.
    2. No abstractions for single-use code.
    3. No "flexibility" or "configurability" that wasn't requested.
    4. No error handling for impossible scenarios.
    5. If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If
yes, simplify.

### Goal-Driven Execution

Define success criteria. Loop until verified.

Transform tasks into verifiable goals:

    "Add validation" → "Write tests for invalid inputs, then make them pass"
    "Fix the bug" → "Write a test that reproduces it, then make it pass"
    "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:

1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]

Strong success criteria let you loop independently. Weak criteria ("make
it work") require constant clarification.

These guidelines are working if: fewer unnecessary changes in diffs, fewer
rewrites due to overcomplication, and clarifying questions come before
implementation rather than after mistakes.
