# Proposal

## Why

The stopped change `backlog-per-file` moves `docs/backlog.md` into one Markdown file per first-named path under a `docs/backlog/` folder plus a `_general.md` file. `RECORDS_RE` in `tools/rules.sh` names only `docs/backlog.md`, so `settled_at` in `tools/gates.sh` and `TEST_ONLY` and `outside_records` in `tools/run_state.sh` would read the moved files as code: a records-only move would rerun the whole check and the reviews. The user approved this edit of the merge gate's rules on 2026-11-21, to run alone in the backlog lane before `backlog-per-file`.

## What Changes

- `RECORDS_RE` also matches a file under `docs/backlog/` ending in `.md` (`docs/backlog/.+\.md$`), beside the existing `docs/backlog.md` alternative, which stays until `backlog-per-file` removes it. A non-Markdown file under the folder and `docs/backlogs.md` do not match.
- The comment above `RECORDS_RE` names the backlog folder.
- `tools/tools_test.sh` cases: the five paths of the brief against `RECORDS_RE`, and `settled_at` (the security gate), `TEST_ONLY` (the check's carry), `outside_records` (`settled`), and `documentation` (`ci_scope`) reading the folder's Markdown files as records.
- The queue line of the user-approved exception reaches `docs/queue-backlog.md` through the planned queue that `plan-apply` copies at the package step, not by a separate edit.

This is outside the roadmap of `docs/architecture.md` section 12: delivery tooling, no editor behavior.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None: no spec covers the delivery tooling, so `skip_specs: true`.

## Out of scope

- The move of the backlog itself, the guard rules, and every reader of the backlog (`backlog-per-file` and its second part).
- No other line of `tools/rules.sh`; no file of the feature lane.
- Assumption: widening `RECORDS_RE` gives the folder's Markdown files exactly the records-only status `docs/backlog.md` has now, and nothing more; `documentation()` already treated any Markdown file as documentation, so CI's scope is unchanged for them.

## Impact

`tools/rules.sh`, `tools/tools_test.sh`, and, through `plan-apply`, `docs/queue-backlog.md`.

- CLAUDE.md: unchanged, it names the records-only paths by no list and the process is unchanged.
- README.md: unchanged, it does not list the records-only paths.
- docs/architecture.md: unchanged, it describes the editor and names no records-only path.
- docs/codebase-map.md: unchanged, its `tools/rules.sh` line names `RECORDS_RE` as the records-only paths without listing them.
