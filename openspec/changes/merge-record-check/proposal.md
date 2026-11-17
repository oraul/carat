# Proposal

## Why

Three of six backlog merges (#161, #162, #166), and since then check-parallel (#175), lsp-container-c (#180), and tab-close-b (#181), recorded a wrong CI or merge head: the workflow records `phase.ci` from the merger's reported `head` and `phase.merge` and `merged` from its reported `sha`, which `tools/run_state.sh` checks only for their hexadecimal shape, so a swapped pair (the squash commit as the CI head, the pushed head as the merge) or a mistyped hash (5920e3652873 for 5920e365287d) is stored as given. The history, the sprint base, and the late-finding stamps all read `merged`.

Separately, `settled_at` in `tools/gates.sh` lets a review or check stand after a records-only diff, and counts `docs/sprints.tsv` by appended rows only. Any appended row passes, so a forged row naming the latest merge, appended after the review, moves the sprint base (the last row's last change) and the sprint-end combined review skips the changes in between (security Low (5) and Low (3) in the backlog). The code map names `settled_at` and `appended_rows` under the stages gate only, though the security and passed gates share them.

## What Changes

- `tools/run_state.sh set CHANGE ci "red|green COMMIT"` and `phase CHANGE ci COMMIT` accept only the pushed head the run state records (7 to 40 of its leading digits), storing its 12-digit form; anything else, or no recorded push, is refused naming both values.
- `tools/run_state.sh set CHANGE merged COMMIT` and `phase CHANGE merge COMMIT` resolve the commit with git and accept it only when it is on main (an ancestor of HEAD or BASE, as the history already counts a merge) and, once the pull request number is recorded, it is the newest commit of BASE (`origin/main`), else of HEAD, whose subject ends with ` (#N)`, the squash merge's title; otherwise they are refused naming the given value and the squash commit found.
- New `tools/run_state.sh sprint-row COMMIT`: prints the row groom appends for the sprint the plan's marker names (`build/plan/sprint`, or `sprint.applied` once groom retired it), computed against the sprints file at COMMIT, refusing when the marker names another sprint than the one in progress there.
- `settled_at` in `tools/gates.sh` counts a `docs/sprints.tsv` change only when its rows are appended (`appended_rows`, as before) and the appended bytes are exactly that one row (new `groom_row`), so an edited, forged, or second row leaves the review or check unsettled.
- `.claude/workflows/deliver-change.js` records the CI result and `phase.ci` at the pushed head, not the merger's reported head; `phase.merge` keeps the merger's sha, which the run state now checks.
- `.claude/agents/merger.md` takes the merged short sha from `git rev-parse --short=12 origin/main` output and stops on a refused record, naming both values; `.claude/agents/retrospective.md` shows the merged commit the run state recorded and names both when the input's differs.
- `docs/codebase-map.md` names the shared `settled_at` helper once, beside the gates that use it.
- Tests in `tools/tools_test.sh`: a CI head not the pushed head refused (set and phase), a CI record before any push refused, a merged commit not on main refused, a merged commit that is not the pull request's squash commit refused naming it, `sprint-row` matching the row groom appended, the gate passing groom's row, and refusing an edited row, a forged row, a second row, and a row for a sprint the marker does not name.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None: the change alters the pipeline's tooling only, no editor behavior (`skip_specs: true`).

## Impact

- `tools/run_state.sh`: `pushed_at`, `squash_commit`, `merged_at`, and `sprint_row_at`; the `set`, `phase`, and new `sprint-row` commands; the header.
- `tools/gates.sh`: `groom_row`, called from `settled_at`; its comment.
- `tools/tools_test.sh`: the new cases; fixtures that set a CI record before a push, a stray merged value, or a merge on another branch write them the new way (a forged key, a recorded push, `BASE=main`).
- `.claude/workflows/deliver-change.js`, `.claude/agents/merger.md`, `.claude/agents/retrospective.md`: as above.
- README.md: changed, the run state paragraph says CI is recorded at the pushed head, the merge only as the squash commit, and the sprint log counts only by groom's row (the docs gate asks for it whenever an agent or workflow file changes).
- CLAUDE.md: unchanged, its run state and gates entries stay true: `sprint-row` is a helper the script's header lists, like every run state command (CLAUDE.md names "every command in the script's header"), and no process step changes.
- docs/architecture.md: unchanged, it does not describe the run state's records or the gates' records-only rule.
- docs/codebase-map.md: changed, the `tools/gates.sh` entry names `settled_at` once for the security, stages, and passed gates and the groom row check; the `tools/run_state.sh` entry names the `set` and `phase` checks and gains `sprint-row`; no file is added, moved, or removed.
- docs/compatibility.md and docs/actions.md: unchanged, no command or action changes.
- `tools/rules.sh`: unchanged (`RECORDS_RE` stays).

Outside the roadmap of `docs/architecture.md` section 12: a pipeline defect (T1) from the backlog, Sprint 14 item 1 of the backlog lane.

## Out of scope

- A merge refused because main moved (the 405 of #169): it stays in the backlog.
- Rewriting the wrong heads already recorded in older run states and history rows.
- The merger's `head` in its notes and the stale check, which compare with the pushed head already.

Minor assumptions: "on main" for a merged commit is the history's own definition (an ancestor of HEAD or of BASE, `merged_on_main`), with the pull request's subject as the stronger check once the number is recorded, so the merger's record in the main checkout and the test repositories without an `origin` agree; a stored CI head and a merged commit are normalized to 12 digits; a CI record with no push recorded is refused, since CI runs only at a pushed head.
