# Design

## Context

See proposal.md, Why. The workflow's merge loop (`.claude/workflows/deliver-change.js`) builds the green and red lines with `set CHANGE ci "RESULT HEAD"`, HEAD the contributor's reported head, and after the merger returns records `phase.ci` at `m.head` and `phase.merge` and `state.merged` at `m.sha`, both typed by the merger. The merger itself runs `set CHANGE merged SHA` in its step 7. `tools/run_state.sh set` checks `merged` and `pushed` for 7 to 40 hexadecimal digits only and writes `ci` as given; `phase` resolves any commit with git. `settled_at` (`tools/gates.sh`) passes a `docs/sprints.tsv` change when `appended_rows` holds, whatever the appended rows say.

## Goals / Non-Goals

Goals: a recorded CI head is the pushed head; a recorded merged commit is the pull request's squash commit on main; an agent's mistyped or swapped value is refused naming both; the records-only exemption accepts only groom's row for the marker's sprint.

Non-Goals: rewriting old records; the refused-merge retry; `tools/rules.sh`.

## Decisions

- The checks live in `tools/run_state.sh`, the only writer of the run state, so every path (the merger's lines, the workflow's record line, a hand-run command) passes them; the workflow cannot run git itself.
- CI head: compared with the recorded `pushed` (full sha) as a string prefix, with no git lookup, so the record line run in the main checkout after the branch is deleted still succeeds. The stored value is the pushed head's first 12 digits. The workflow now builds the CI lines and `phase.ci` from the pushed head it already holds (`pushedHead`), so the check passes by construction and the merger's `head` is only noted.
- Merged commit: resolved with `git rev-parse`, on main by `merged_on_main` (HEAD or BASE, the history's rule). Once `pr` is recorded, the squash commit is found by subject: the newest commit of BASE (`origin/main`), else of HEAD, whose subject ends with ` (#N)`, which GitHub's squash title always carries and CLAUDE.md requires; the value must be that commit. A mistyped hash resolves to nothing and a pushed head is not on main or lacks the subject, so both are refused, the message naming the given value and the squash commit. Alternative: let `phase merge` find the squash commit itself with no argument; rejected, since the brief asks for a mismatch to stop naming both values rather than silently replacing an agent's value.
- Groom's row: `sprint-row COMMIT` recomputes the row with groom's own `sprint_state` and `sprint_row` against a temporary copy of the sprints file at COMMIT, the history rows of the working tree, and the marker's sprint (`build/plan/sprint`, else `sprint.applied`, which groom leaves). `groom_row` in `gates.sh` compares the bytes appended since COMMIT with that one line; a second row, a forged row (another last change, another count), or a row for another sprint differ. The gate calls the `run_state.sh` beside it, so the merger's copy of main's gates run from `tmp/.merge-gates` against the lane's `build/` checks the row the same way. An edited earlier row still fails `appended_rows` first.
- Test fixtures that wrote a CI record before any push, a merged value naming no commit, or a merge on another branch now forge the key, record a push first, or pass `BASE=main`, keeping what each case proves.

## Risks / Trade-offs

- The row's figures come from the history rows at HEAD; a history row of a later change does not change it, since the row stops at the fifth counted change, as groom's does.
- A run whose pull request number was never recorded falls back to the on-main check alone.
