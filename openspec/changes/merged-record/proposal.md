# Proposal

## Why

vim-folds-windows held `phase.merge` with `merged` empty: the merger's `set CHANGE merged SHA` did not run, and the close's `phase CHANGE merge merged` resolved the squash commit and wrote only `phase.merge`. `pending_list` and `sprint_state` find a merge only by `merged` (`merged_commit`, which prints nothing for an empty value), so `review_due` left the change out of the sprint count without a word until the main session set `merged` by hand.

This is a pipeline defect outside the roadmap of `docs/architecture.md` section 12, run by the user-approved exception of Sprint 21.

## What Changes

- `tools/run_state.sh`, `phase CHANGE merge [COMMIT|merged [REPORTED]]`: after the commit is checked (`merged_at`, or `squash_of_change` for the word `merged`, both requiring a commit on HEAD or origin/main and, once the pull request is recorded, its squash commit), the merge phase writes `merged` at that commit when none is recorded, before `phase.merge`; a recorded `merged` naming another commit refuses the phase and writes neither. No run state written by `phase` holds a merge without its merged commit.
- `tools/run_state.sh`, `merge_unrecorded`: the run states recording a valid `phase.merge` but no merged commit, no history row, and not a review run (`REVIEW_RUNS`), as `NAME at COMMIT`. `sprint_state` keeps them in `sprint_uncounted`; `review_due`, unless the sprint's plan already waits, prints `not due: sprint-N cannot count a merge phase recorded without its merged commit: NAME at COMMIT; record each with sh tools/run_state.sh set NAME merged COMMIT` and exits 1, so a run state written before this change, or edited by hand, holds the sprint by name instead of being left out silently.
- `tools/tools_test.sh`: cases proving the merged commit is written with the merge phase (both forms), a differing recorded `merged` refuses it writing nothing, and `review-due` names such a run state, leaving out a review run's and one with a history row; the `trusted` case's key order follows the new write order.

## Capabilities

### New Capabilities

None: the change alters the delivery tooling (`skip_specs: true`).

### Modified Capabilities

None.

## Out of scope

- The merger's step 7 still runs `set CHANGE merged SHA`; it now agrees with, or precedes, what the close writes.
- `pending_list` keeps skipping a `merged` value that names no commit on main, as tested.
- `groom` and `sprint-row` count history rows, which `history` already refuses to append for an unmerged run, naming it; they are unchanged.
- No `tools/rules.sh` edit.

## Impact

- README.md: the pipeline paragraph says the merge phase writes the merged commit and `review-due` names a run state it cannot count.
- docs/codebase-map.md: area 1's `tools/run_state.sh` entry names the merge write and `merge_unrecorded`.
- CLAUDE.md: unchanged, it does not describe the run state's merge record or review-due's lines.
- docs/architecture.md: unchanged, no layer or port is touched.
