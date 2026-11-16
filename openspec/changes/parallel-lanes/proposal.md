# Proposal

## Why

A feature delivery and a backlog delivery cannot run at once (T1 pipeline, user request, estimated medium, Sprint 10's approved exception): every package step writes records the other lane also writes. It copies both of the planner's `build/plan/queue-*.md`, so a second planner overwrites the first's files and one lane's package step rewrites the other lane's queue; `history` appends the rows of every pending change, so a backlog package step writes `docs/metrics-feature.tsv`; and `groom`, the fold of the findings into `docs/backlog.md` and the `docs/sprints.tsv` row, lands from whichever package step runs first. This run is the records separation, the brief's parallel-lanes-a (parts 2, 3, and 4); the worktrees are parallel-lanes-b.

## What Changes

- A delivery's planner writes under `build/plan/<change>/`, its own directory, so two planners never overwrite each other; the sprint planner keeps `build/plan/` itself (`sprint`, `groom.txt`, `groomed.md`, the sprint's two lane queues).
- `sh tools/run_state.sh plan-apply CHANGE`, new: applies that directory for the change's lane only: copies `queue-LANE.md` over `docs/queue-LANE.md` (the other lane's queue, if the planner wrote one, left and said so), `goals.md` over `docs/goals.md`, and appends `backlog.md` to `docs/findings/CHANGE.md`. The lane is `lane_of`'s, which for a change not yet merged now reads the lane queue at HEAD or BASE naming it, else its branch (`feature/` the feature lane, any other the backlog lane).
- `history CHANGE` appends the rows of the pending changes of CHANGE's lane only, leaving the other lane's to that lane's next package step, which says so; a sprint's records change (`sprint-N-records`) and `history` without a change append every lane's rows, as before.
- `groom CHANGE` applies a waiting sprint plan only for CHANGE `sprint-N-records`, N the closed sprint the marker names, and refuses any other change, so the fold, the sprint's queues, and the sprints row are written once, by sprint-planning's records change; `plan-needed` takes that change as not needed (small), unless a failing periodic security review comes first.
- `.claude/workflows/sprint-planning.js` gets a Records phase: after the plan and the record, it delivers `sprint-N-records` on `chore/sprint-N-records` through `.claude/workflows/deliver-change.js`, whose contributor runs `history` and `groom` in its implement step; `deliver-change.js` points the planner at `build/plan/<change>/`, and its package step runs `plan-apply` and `history` for the change, never `groom` (nothing for the records change, which applied the plan already).
- `tools/agent_guard.sh` lets the contributor run `plan-apply`; `.claude/agents/planner.md` and `contributor.md` name the new directory and steps.
- `tools/tools_test.sh` cases over fixture repositories; docs: README.md's delivery and sprint planning steps, `docs/codebase-map.md` area 1.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None: the change alters the delivery pipeline's records, which no spec under `openspec/specs/` describes (`skip_specs: true`).

## Impact

- `tools/run_state.sh`, `tools/agent_guard.sh`, `tools/tools_test.sh`, `.claude/workflows/deliver-change.js`, `.claude/workflows/sprint-planning.js`, `.claude/agents/planner.md`, `.claude/agents/contributor.md`.
- `tools/rules.sh`: unchanged; RECORDS_RE already holds every file the records change and the package step commit, and TOOLS_RE the files the new cases read.
- CLAUDE.md: unchanged, its Sprints bullet still says the next package step applies the sprint's plan with `groom`, and its Run state bullet the next change's package step; an agent's instruction does not authorize an edit of CLAUDE.md, so the wording is left for the user to approve, with parallel-lanes-b, which edits the same Agents section for the two-lanes rule.
- README.md: changed, the delivery and sprint planning steps name the plan directory, `plan-apply`, the lane-only history, and the records change.
- docs/architecture.md: unchanged, it describes the editor's architecture and the test machinery, not the delivery workflow's records.
- docs/codebase-map.md: changed, area 1's flow names the records change; no file is added, moved, or removed.

Outside the roadmap of `docs/architecture.md` section 12: a pipeline change (T1) the user requested, by Sprint 10's approved exception. One reviewable pull request.

Minor assumptions: the plan directory is per change (`build/plan/<change>/`), which the brief allows beside per lane, since a change name is unique and its lane is derived; the records change is a full delivery started by sprint-planning (the brief's "its own records change"), so its records pass the checker, both reviews, and the merge gates like any change, and a stopped one resumes with `/deliver sprint-N-records`; its run name matches REVIEW_RUNS, so no sprint counts it; `history` with no change keeps appending every lane, its behavior for a manual call.

## Out of scope

- The worktrees under a hidden `tmp/` directory, merging a moved main into a running delivery, and the rule that one feature-lane and one backlog-lane delivery may run at once (parallel-lanes-b); this change does not let two deliveries run at once.
- Any change to `tools/rules.sh`, the groom checks themselves, `backlog-pick`, or the budgets.
