# Design

## Context

`tools/agent_guard.sh` parses each run state command of a profile; `lane-close` and `merge-main` were listed with no argument check, so a name such as `../x` reached `run_state.sh`. `tools/gates.sh` settles a security pass across a records-only diff only when the appended `docs/sprints.tsv` bytes equal groom's row (`groom_row`).

## Goals / Non-Goals

**Goals:**
- Every command that names a change takes a `CHANGE_NAME` only.
- The sprint row is accepted only byte for byte, from committed rows.

**Non-Goals:**
- The RISKY_CONFIG pager keys (they edit `tools/rules.sh`) and the headings whose fix the queue does not state.

## Decisions

- `lane-close` and `merge-main` join `read:moved` and the others in a case with the `CHANGE_NAME` match, refusing none, zero, or two arguments.
- `groom_row` writes both sides to temporary files and compares them with `cmp`, since a command substitution drops trailing line breaks; the history files are checked with the existing `appended_rows`.
- `sprint-row COMMIT committed` sets `history_at=HEAD` for `lane_rows`; the package step's own `sprint-row COMMIT` (groom) keeps reading the working tree, where its rows are not yet committed.
- `add_note` generalizes its security repeat check to the `quality` kind, comparing the whole text after the kind word.
- The merger's `lane-close CHANGE` is bound to the change merged: the guard reads `build/pipeline/CHANGE.json` (a regular file, not a link) and requires its `pushed` and `gated` to hold the same 40 digits, as `merge_tool` does; the merge gates reset every run state's `gated` before one passes, so one change qualifies at a time and a misdirected `lane-close other` is refused. A resume after another lane's gates reset `gated` is refused too, and the worktree is then removed by hand.
- The contributor's `merge-main CHANGE` is bound by its directory: `merge_main` takes no name and merges into the branch of the directory it runs in, so the guard requires the call's `cd_worktree` to be `tmp/.lane-CHANGE` (relative or absolute).
