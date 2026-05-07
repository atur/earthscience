# Cascade deletion

This document describes how `ON DELETE CASCADE` foreign keys propagate
through the `dbnext` schema, plus the two constraint triggers that
guard against orphaned `project_record` rows.

All `FOREIGN KEY` clauses in `sql/db_schema.sql` use either no action
(the PostgreSQL default — block the delete) or `ON DELETE CASCADE`.
There is no `SET NULL`, `RESTRICT`, or `SET DEFAULT` anywhere in the
schema.

## Cascades from `project_record`

Deleting a row in `project_record` cascades to **12 child/link
tables**. Two of those (`project_record_determination` and
`project_record_user`) cascade further into their own keyword link
tables, so a single `DELETE` on `project_record` can affect up to 14
tables.

| # | Child table                        | FK column                               | Constraint                                          |
|---|------------------------------------|-----------------------------------------|-----------------------------------------------------|
| 1 | `external_identifier_project_record` | `id_project_record`                   | `fk_eipr_project_record`                            |
| 2 | `project_record_geometry`          | `id_record`                             | `fk_geometry_record`                                |
| 3 | `project_record_media`             | `id_project_record`                     | `fk_prm_project_record`                             |
| 4 | `project_record_determination`     | `id_project_record`                     | `fk_prd_record`                                     |
| 5 | `project_record_identifier`        | `id_project_record`                     | `fk_pri_project_record`                             |
| 6 | `project_record_keyword`           | `id_project_record`                     | `fk_prk_project_record`                             |
| 7 | `project_record_project`           | `id_project_record`                     | `fk_project_record_project_id_project_record` (NOT VALID) |
| 8 | `project_record_user`              | `id_project_record`                     | `fk_project_record_user_id_project_record`          |
| 9 | `project_record_parent`            | `id_project_record`                     | `fk_prp_project_record`                             |
| 10 | `project_record_parent`           | `id_project_record_parent`              | `fk_prp_parent`                                     |
| 11 | `project_record_record`           | `id_project_record_1`                   | `fk_prr_project_record_1`                           |
| 12 | `project_record_record`           | `id_project_record_2`                   | `fk_prr_project_record_2`                           |

### Grandchildren (second-level cascades)

When `project_record_determination` rows are removed by the cascade
above, they pull their keyword tags with them:

| Grandchild table                       | FK column                          | Constraint                  |
|----------------------------------------|------------------------------------|-----------------------------|
| `project_record_determination_keyword` | `id_project_record_determination`  | `fk_prdk_determination`     |

When `project_record_user` rows are removed, the same happens for
their keyword roles:

| Grandchild table              | FK column                | Constraint                                                    |
|-------------------------------|--------------------------|---------------------------------------------------------------|
| `project_record_user_keyword` | `id_project_record_user` | `fk_project_record_user_keyword_project_record_user` (NOT VALID) |

## Cascades from `keyword`

Deleting a keyword removes every tag/typing reference to it. This is
intentional — `keyword` is a controlled vocabulary, and orphaned link
rows would lose their meaning.

| Child table                            | FK column     | Constraint                              |
|----------------------------------------|---------------|-----------------------------------------|
| `item_keyword`                         | `id_keyword`  | `fk_item_keyword_keyword`               |
| `item_list_keyword`                    | `id_keyword`  | `fk_ilk_keyword`                        |
| `item_list_item_keyword`               | `id_keyword`  | `fk_ilik_keyword`                       |
| `project_keyword`                      | `id_keyword`  | `fk_pk_keyword`                         |
| `project_record_keyword`               | `id_keyword`  | `fk_prk_keyword`                        |
| `project_record_determination_keyword` | `id_keyword`  | `fk_prdk_keyword`                       |
| `project_record_user_keyword`          | `id_keyword`  | `fk_project_record_user_keyword`        |
| `users_keyword`                        | `id_keyword`  | `fk_user_keyword` (NOT VALID)           |

Note: deleting a keyword does **not** cascade through the typed-slot
columns (`project_record_record.id_keyword`,
`project_record_parent.id_keyword`,
`project_record_identifier.id_keyword`,
`project_record_determination.id_determination_method`). Those FKs
have no `ON DELETE` action and will block the delete.

## Cascades from `item`

| Child table       | FK column  | Constraint              |
|-------------------|------------|-------------------------|
| `item_list_item`  | `id_item`  | `fk_ili_item`           |
| `item_keyword`    | `id_item`  | `fk_item_keyword_item`  |

Deleting an item also indirectly removes:

- `item_list_item_keyword` (via `item_list_item` cascade)
- `project_record_determination` (via `item_list_item` cascade —
  see below)

## Cascades from `item_list_item`

| Child table                     | FK column            | Constraint    |
|---------------------------------|----------------------|---------------|
| `item_list_item_keyword`        | `id_item_list_item`  | `fk_ilik_item`|
| `project_record_determination`  | `id_item_list_item`  | `fk_prd_item` |

The cascade into `project_record_determination` is significant:
removing an item from a list (or removing the underlying item)
silently drops every determination that pointed at that list entry,
which can in turn trip the "last determination" guard described
below.

## Constraint triggers (deferred)

Two constraint triggers protect `project_record` from ending up in an
invalid state. Both are `DEFERRABLE INITIALLY DEFERRED`, so they fire
at transaction commit, not at statement time.

### `trg_project_record_requires_project`

- Defined on: `project_record`, `AFTER INSERT`.
- Function: `dbnext.check_project_record_has_project()`.
- Rule: every newly inserted `project_record` must have at least one
  matching row in `project_record_project` by commit time.
- How to satisfy: insert into `project_record_project` in the same
  transaction (e.g. wrap the two inserts in `BEGIN; … COMMIT;`).

### `trg_prevent_last_project_association_delete`

- Defined on: `project_record_project`, `AFTER DELETE`.
- Function: `dbnext.prevent_last_project_record_project_delete()`.
- Rule: cannot remove the last `project_record_project` row for a
  given `project_record`.
- Short-circuit: if the parent `project_record` was itself deleted
  earlier in the same transaction, the trigger returns without
  raising. This is what allows `DELETE FROM project_record …` to
  cascade cleanly through `project_record_project` without tripping
  the guard.

### `trg_prevent_last_determination_delete`

- Defined on: `project_record_determination`, `AFTER DELETE`.
- Function: `dbnext.prevent_last_determination_delete()`.
- Rule: cannot remove the last `project_record_determination` row for
  a given `project_record`.
- Short-circuit: same pattern — if the parent `project_record` was
  deleted earlier in the transaction, the trigger returns silently so
  the cascade can complete.

## Summary: what one `DELETE FROM project_record` touches

In the worst case (a record with the full set of associations), a
single delete fans out to these tables:

```
project_record
├── external_identifier_project_record
├── project_record_geometry
├── project_record_media
├── project_record_identifier
├── project_record_keyword
├── project_record_project          (constraint trigger short-circuits)
├── project_record_parent           (both directions)
├── project_record_record           (both directions)
├── project_record_determination    (constraint trigger short-circuits)
│   └── project_record_determination_keyword
└── project_record_user
    └── project_record_user_keyword
```

## NOT VALID cascades

Three cascade FKs are marked `NOT VALID` because historical rows may
violate them. New inserts are still validated, and the cascade
behaviour is unaffected — `NOT VALID` only skips the initial
back-check at constraint creation time.

- `fk_project_record_project_id_project_record`
- `fk_project_record_user_keyword_project_record_user`
- `fk_user_keyword`

Do not run `ALTER TABLE … VALIDATE CONSTRAINT` on these without first
cleaning up the offending rows.
