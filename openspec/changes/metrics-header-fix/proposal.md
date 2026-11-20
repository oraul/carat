# Proposal

## Why

closing-loop (#227) added `advisories_closed` and `advisories_left` to `HEADER` (`tools/run_state.sh:508`) and to each history row, but `append_history` writes `HEADER` only into a lane file that does not exist (`:2436`), so both lane histories kept their 22-column header while every row from `docs/metrics-feature.tsv` line 65 and `docs/metrics-backlog.tsv` line 126 on carries 24 fields (T2, the user's request of 2026-11-20, estimated small). Nothing compares a lane file's header with `HEADER` or counts a row's fields, so the next column added would repeat it unseen.

## What Changes

- `docs/metrics-feature.tsv` and `docs/metrics-backlog.tsv`: line 1 becomes `HEADER`, and each of the 187 older 22-field rows (feature lines 2 to 64, backlog lines 2 to 125) gains two trailing `-` fields for `advisories_closed` and `advisories_left`; no other field or row changes.
- `append_history` (`tools/run_state.sh`) refuses, before it appends any row, when a non-empty lane file's line 1 is not `HEADER` exactly, naming the file and what to do, and appends nothing; a lane file that is absent or empty gets `HEADER` first.
- `tools/docs_lint.sh` gains the `histories` check: every non-blank row of each `docs/metrics-*.tsv` has its line 1's field count, a row that does not named by file, line, and counts.
- `docs/queue-backlog.md`: the user-approved exception line for this change under its Sprint 23 heading.
- Cases in `tools/tools_test.sh`: history refuses a lane file whose header is short of `HEADER` (failing before the fix), refuses a header ending in a carriage return, appends nothing then, and writes the header into an empty lane file; docs-lint passes histories whose rows match their header and refuses one that does not.
- Docs: the comment above `append_history`, the usage header of `tools/docs_lint.sh`, the README's docs-lint line and documents paragraph, and the map's `tools/run_state.sh` and `tools/docs_lint.sh` entries.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None: the change alters the delivery pipeline's records and checks, which no spec under `openspec/specs/` describes (`skip_specs: true`).

## Impact

- `tools/run_state.sh`, `tools/docs_lint.sh`, `tools/tools_test.sh`, `docs/metrics-feature.tsv`, `docs/metrics-backlog.tsv`, `docs/queue-backlog.md`.
- README.md: changed, docs-lint's line and the documents paragraph name the history field-count check.
- CLAUDE.md: unchanged, its run state and checks lines (`history` commits a lane's rows, `make docs-lint`) still hold; the header rule lives in `tools/run_state.sh`, the README, and the map.
- docs/architecture.md: unchanged, it does not describe the lane histories or docs-lint's checks.
- docs/codebase-map.md: changed, the `tools/run_state.sh` and `tools/docs_lint.sh` entries; no file is added, moved, or removed.

Outside the roadmap of `docs/architecture.md` section 12: a pipeline defect fix by the user's request. One reviewable pull request; `tools/rules.sh` is not edited.

Minor assumptions:
- The brief allows refusing or rewriting a differing header; the writer refuses, since a rewrite under the lanes' `merge=union` merge could keep two headers, and the change that adds a column is the one that knows how older rows are padded.
- The check is every lane file's header, not only the one being appended to, so no row is written while either history is inconsistent.
- An empty lane file is treated as absent (header written), where it used to get a row with no header.
- docs-lint counts fields against each file's own line 1, as the brief asks; the equality with `HEADER` is the writer's check, since docs-lint does not read `tools/run_state.sh`.

## Out of scope

- Any change to the columns, their order, or the values of existing fields; the feature lane's rows appended after this change's base.
- A migration helper for a future column addition.
