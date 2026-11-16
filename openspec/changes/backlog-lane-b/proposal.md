# Proposal

## Why

The backlog lane exists (#153) but nothing chooses its work (T1 pipeline, user request, estimated medium, Sprint 10's third pipeline change by the user's approved exception): backlog items are queued by hand, so `docs/backlog.md` only grows, and a sprint's two backlog items carry no rule for which entries they close.

## What Changes

- `sh tools/run_state.sh backlog-pick [FILE...]`, beside `backlog-dups`: reads the backlog entries (a `##` or deeper heading with a `- Location:` or `- Where:` line, or a path:line in the heading, and a `- Why:` or `- Why it matters:` line; any other heading a section) of the FILEs in order, or of the backlog and the findings files when none is given; skips an entry whose heading a queued item of either lane names; maps each entry's Location path, else its heading's path, to the `docs/codebase-map.md` area naming it (a bullet's leading path first, then any backticked path on the area's lines, Tests: lines and multi-path bullets included), reporting an entry whose Location names no mapped path as `unmapped:` and placing it nowhere; and prints the next batches (`PICK_BATCHES`, 2, the sprint's two backlog items), each of one area: the areas of the entries naming security (title or Why) first, then the area of the oldest entry, an area holding 5 or more giving at most 10 of its entries, its security entries first then the oldest, an area under 5 giving its security entries alone, or passed over for the next when it has none.
- The planner's sprint mode (`.claude/agents/planner.md`) fills the sprint's two backlog items from the pick's batches, each item listing its batch's headings in its Backlog part, so the existing removal by heading at the merge closes them; runs a one-time triage, grooming every stale entry (code gone or fixed by `fixed`, a duplicate by `duplicate`) and recording it once as a `Backlog triage:` decision of the backlog queue, never again unless asked; and, once about 5 backlog-lane runs are in `docs/metrics-backlog.tsv`, compares them with `docs/metrics-feature.tsv` and proposes a budget, call cap, or tier change only from those figures.
- `.claude/workflows/sprint-planning.js` names the pick and the triage in its Plan step and in the planner's sprint prompt.
- `tools/tools_test.sh` cases over fixture backlogs and a fixture map; docs: `docs/codebase-map.md` area 1, README.md's sprint planning step.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None: the change alters the delivery pipeline's planning, which no spec under `openspec/specs/` describes (`skip_specs: true`).

## Impact

- `tools/run_state.sh`, `tools/tools_test.sh`, `.claude/agents/planner.md`, `.claude/workflows/sprint-planning.js`.
- `tools/rules.sh`: unchanged; TOOLS_RE already covers the agents, the workflows, and the code map the new cases read.
- CLAUDE.md: unchanged, the pick is a `tools/run_state.sh` command its Commands section covers by the script's header, and the sprint mode's steps belong to the planner's file; CLAUDE.md sits 9 bytes under its budget.
- README.md: changed, the sprint planning step names the pick, the triage, and the calibration.
- docs/architecture.md: unchanged, it describes the editor's architecture and the test machinery, not the delivery workflow's planning.
- docs/codebase-map.md: changed, area 1's `tools/run_state.sh` entry names `backlog-pick`; no file is added, moved, or removed.

Outside the roadmap of `docs/architecture.md` section 12: a pipeline change (T1) the user requested, by Sprint 10's approved exception. One reviewable pull request.

Minor assumptions: the pick is a `tools/run_state.sh` command (the planner's choice), taking files so its cases read fixtures only; it prints two batches, the sprint's two backlog items, each of a different area, an area's entries beyond 10 left to a later sprint; an area under 5 that holds a security entry gives its security entries alone, so a security entry never waits, and one under 5 without one is passed over; an entry counts as named by a queued item when its heading text appears in `docs/queue-feature.md` or `docs/queue-backlog.md`; a Location matches a map path exactly or under a mapped directory, after its backticks and its `:line` are dropped; the triage is recorded in the backlog queue's Decisions, since `docs/sprints.tsv` has no notes column, and found again by `git log -S` on that file; the planner's text makes room by tightening its wording, the budget never raised.

## Out of scope

- Any change to `groom`, the removal by heading, `tools/rules.sh`, the file budgets, or the queue budget.
- The triage itself and the calibration's figures, which the next sprint-planning run and later runs make.
