# Design

## Context

The scout pack `tmp/scout/build-and-ci-f31f4e8-20261104T165555Z.md` holds the line references; they hold at f31f4e8. `tools/docs_lint.sh` budgets `CLAUDE.md`, the agent files, and `docs/architecture.md` by bytes, not the queue. The planner reads all of `docs/backlog.md` (80,710 bytes) and rewrites the whole queue each planned run. A scout copies rules from `CLAUDE.md` and `docs/architecture.md` (88,054 bytes) into its pack (its step 8). On the plan-skip path the workflow builds the brief from the `item:` line the resume agent re-emits from `tools/run_state.sh plan-needed`.

## Goals / Non-Goals

Goals: a byte budget on the queue; less read and written by the planner, the scouts, and the implement start; the queue item read from the file, never from a model's copy. Non-goals: the resume of a change whose tasks are done (`run-resume`), what the harness injects into every agent, tool-call caps (`run-budgets`).

## Decisions

### The queue gets a byte budget

`BUDGETS` gains `docs/queue.md 17369`, checked by `check_budgets` like the others. The planner is told the budget lives there and checks `build/plan/queue.md` with `wc -c` before returning; the package step's `make docs-lint` refuses a queue over it. The planned queue (16,921 bytes) replaces `docs/queue.md` now, so every check of this branch passes the budget.

### The planner reads and writes less

Its step 1 reads `docs/backlog.md` by its headings (`grep -n '^## '`) and opens only the entries a decision places; the backlog keeps the locations, so an item names its problem, numbers, and acceptance and points to the backlog for the rest. Decisions are one line each, only this plan's, and the returned decisions repeat that text. Every decision still cites a number: step 2 is unchanged.

### Scouts answer about existing code only

The scout plan's prompt asks for the existing code the change edits or hooks into (callers, registration, tests), never code the change will add, and leaves out an area whose only edits are new files: in `buffer-substitute` packs reported gaps for code that did not exist yet. The scout drops its rules step and the pack's Rules section (the contributor holds `CLAUDE.md`, and the map's Rules line names the sections, which the scout now copies as that one line), quotes a design only for the entry points of its question, and keeps the pack to about 150 lines. The contributor trusts a current pack's lines: it opens a covered file only at the lines it edits, and reads the authoring guides only for Ruby code.

### The item comes from the file

`brief` is the input when it is a request; otherwise it is an instruction to read the item naming the change in `docs/queue.md` (and, when none names it, the existing OpenSpec change). The scout plan, each scout (whose prompt now carries the brief), and the contributor read the item with their own tools, so no model re-emits it. `plan_needed` prints only its first line; the `RESUME.plan` field is that line, still read for the estimate and the skip decision.

Alternative rejected: a `tools/run_state.sh item` command, which would need a guard form that only takes effect after the merge, for what Grep already does.

## Risks / Trade-offs

- A smaller pack may leave the contributor to search more; the acceptance watches scout plus implement output tokens together and quality first pass, so a loss shows in the next three runs' history rows.
- A queue at its budget forces the planner to fold or shorten items rather than drop a finding; the backlog keeps the detail.
