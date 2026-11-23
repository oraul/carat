# Proposal

## Why

Five security Lows of the guard and gate scripts and four pipeline defects are queued as `sprint-guard-lows`. The guard accepted any word as the change name of `lane-close` and `merge-main`, the records-only gate trusted a sprint row read through a command substitution (trailing line breaks dropped) and history rows read from the working tree, and a `/sprint` rerun after a partial review recorded the planner's quality notes twice.

## What Changes

- Change `tools/agent_guard.sh`: the merger's `lane-close` and the contributor's `merge-main` take exactly one argument, a `CHANGE_NAME`, as every other run state command that names a change does.
- Change `tools/gates.sh` (`groom_row`): compare the appended sprint row with groom's row byte for byte as files, so a trailing blank line no longer passes; refuse a branch whose lane history files were edited, not only appended to, since the security review's commit; read groom's row from HEAD's committed history rows (`sprint-row COMMIT committed`), never the working tree.
- Add to `tools/run_state.sh`: `sprint-row COMMIT committed`, which reads the history rows with `git show HEAD:FILE` (`lane_rows`, `history_at`); `add_note` drops an exact repeat of a `quality` note as it drops one of a `security` note.
- Confirm the Security line's suffix and the Sweep line are already proved by the cases added with 8b8e44e (#307): no code change.
- Add tools-test cases that fail before each fix: the guard's refusals, the blank line after groom's row, an edited earlier history row, a working-tree edit of the history rows, and the repeated quality note.

Not fixed here, recorded in `docs/findings/sprint-guard-lows.md` with the reason: the RISKY_CONFIG pager keys (they edit `tools/rules.sh`, queued as `risky-config-pager`); the notes prompt's finding text, the package step's post-review prose edit, the budget line's output share, `spec_validate.sh`'s command variable, and `path_of`, whose queue headings name a location but no fix the delivery can derive without reading the backlog entries; the untracked sprint marker, whose value `sprint-row` checks against the committed sprint log.

Assumptions: the history rows of a branch's own package step are appended to the lane files after the review, so the gate accepts appended rows and refuses edits of earlier ones, and does not reconstruct the rows at the reviewed commit.

## Capabilities

### New Capabilities

### Modified Capabilities

## Impact

- Code: `tools/agent_guard.sh`, `tools/gates.sh`, `tools/run_state.sh`.
- Tests: `tools/tools_test.sh` (new cases, none changed).
- Docs: `docs/codebase-map.md` (the `sprint-row` words of the `tools/run_state.sh` entry).
- README.md: unchanged, no user-visible behavior or spec changed.
- CLAUDE.md: unchanged, the guard's forms are described in `tools/agent_guard.sh`.
- docs/architecture.md: unchanged, no spec changed.
- No edit of `tools/rules.sh`.
