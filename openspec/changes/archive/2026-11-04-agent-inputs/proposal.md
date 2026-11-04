# Proposal

## Why

A run spends 1.0M to 1.6M total tokens against 0.24M to 0.40M output, so what agents read at their start dominates its cost. The plan phase took 33,425 output tokens in `pipeline-speed-b` and 30,587 in `buffer-substitute` (20,364 on average in pull requests 42 to 44) while `docs/queue.md` grew from 17,369 to 23,716 bytes, with nothing holding it back. Scouts cost 30,144 and 93,883 output tokens in those runs without cutting the contributor's calls (62 and 105), their packs quoting rules the contributor already holds and searching for code the change had not yet written. On the plan-skip path the queue item reaches the scouts and the contributor as the resume agent's re-emitted copy (`.claude/workflows/deliver-change.js:559`), output tokens that can come back truncated. This is item 2 of `docs/queue.md`, outside the editor roadmap of `docs/architecture.md` section 12: it changes the delivery workflow only.

## What Changes

- Queue budget: `make docs-lint` holds `docs/queue.md` to 17,369 bytes (`BUDGETS` in `tools/docs_lint.sh`), and the planner's queue, at 16,921 bytes, replaces the 23,716-byte one.
- Planner inputs and output: the planner reads `docs/backlog.md` by its headings and opens only the entries a decision places, writes `build/plan/queue.md` within the queue's budget (checked with `wc -c`), keeps locations in the backlog entries rather than the items, and writes one line per decision.
- Scout and implement inputs: the scout plan asks only about existing code the change edits or hooks into and names no area whose only edits are new files; a scout reads the change's brief, stays at the entry points its question names, and no longer copies `CLAUDE.md` or `docs/architecture.md` rules into its pack (the contributor holds `CLAUDE.md`, the map names the sections), in a pack of at most about 150 lines; the contributor opens a file a current pack covers only at the lines it edits, and reads `docs/examples.md` and `docs/spinel-notes.md` for Ruby code only.
- Item from the file: when the brief is only the change name, the workflow tells the scout plan, each scout, and the contributor to read the item naming the change in `docs/queue.md` themselves; `plan-needed` no longer prints an `item:` line and the resume schema no longer returns one.
- The plan's bookkeeping in `docs/backlog.md`: four entries of periodic review f31f4e8 added, three stale figures and the queued pointers updated, and the plan-skip entry this change fixes removed.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None: the change touches the delivery workflow, its agents, and its scripts, and no editor behavior, so it sets `skip_specs: true`.

## Impact

- `tools/docs_lint.sh`, `tools/run_state.sh` (`plan_needed`), `tools/tools_test.sh`.
- `.claude/workflows/deliver-change.js` (resume schema, brief, scout plan and scout prompts), `.claude/agents/planner.md`, `scout.md`, `contributor.md`.
- `docs/queue.md`, `docs/backlog.md`, `docs/codebase-map.md` area 1.

## Out of scope

- A resume whose tasks are all done skipping the scouts and the full implement start (proposal 1 of `pipeline-speed-c`): the planner placed it at the head of `run-resume` (item 6 of the plan), a fifth part past the size rule here.
- Agents that never edit receiving all of `CLAUDE.md`: the harness injects it into every custom agent start and no agent file setting turns that off, so the lever is its size, which `docs-currency` cuts to 27,648 bytes; recorded in `docs/backlog.md`.
- The tool-call caps and the early budget note (`run-budgets`).

## Assumptions

- The budget is 17,369 bytes exactly, the acceptance's ceiling; the planned queue fits it at 16,921, and no lower figure would leave the planner room to place findings.
- Copying `build/plan/queue.md` over `docs/queue.md` is done in this change's implement step, not only at package, so the docs-lint stage passes at every check of the branch; the package step's copy is then a no-op.
- The plan-phase and scout-plus-implement token targets of the acceptance are measured over the next three planned, tooling, and feature runs; this change makes the instruction and input changes, and those runs' history rows show the result.
- The hooks run `origin/main`'s guard and this session loaded the old agent files, so the new instructions take effect from the next run.
