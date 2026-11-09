# Proposal

## Why

Quality first pass is 16 of 47 recorded runs, and most blockers name rules a machine can check but nothing does: stale doc prose in `README.md`, `docs/architecture.md`, or `CLAUDE.md` (9 blockers; the latest, `README.md:68` at #85, said the docs floats were plain text after they were styled), behavior or a spec scenario with no test (9), a code map line naming a method its file does not define (2), and an `Array[untyped]` of program objects outside a list class, against `docs/spinel-notes.md` (1, `Buffer#diagnostics` at the `diagnostics-display` run; `Buffer#styles` was the same finding at #85). Each passed `make check` and reached the quality review, costing a fix round.

This change is outside the roadmap of `docs/architecture.md` section 12: it repairs the delivery pipeline (`docs/queue.md` item 1, `implement-contracts-b`, split at start).

## What Changes

- `make lint` refuses a code map bullet whose method list (the code spans after the first `; ` of a file's line) names a method, attribute, or record member the file does not define.
- `make lint` refuses an `Array[untyped]` parameter in a signature unless it is the typed element reader form `(Array[untyped], Integer) -> T` or its file is in a recorded exemption, and refuses an assignment from another file to a member pinned `Array[untyped]`, so a list of program objects stays a class of its own with a typed reader. `Buffer#styles` is exempted with its owner, queue item `hover-tidy`.
- `tools/gates.sh docs` refuses a branch that changes a spec (a delta spec or a main spec) but leaves `README.md` or `docs/architecture.md` as they were, and a branch that changes a process file (agents, workflows, commands, `Makefile`, `tools/gates.sh`, `tools/run_state.sh`, `tools/agent_guard.sh`) but leaves `CLAUDE.md`, unless the change's proposal says why in a line `- README.md: unchanged, REASON` (likewise for the other two).
- A new gate, `tools/gates.sh scenarios`, in `static` and `pre-push`, refuses a branch whose delta specs hold an ADDED or MODIFIED scenario that no file under `test/` or `tools/tools_test.sh` names.
- `openspec/config.yaml` tells the proposal and the specs about both gates; `CLAUDE.md`, the code map, and the backlog follow.

## Out of scope

- The other two checks of the item, a message literal in a second file and a def shadowing a reader: queue item `implement-contracts-c`.
- Fixing `Buffer#styles` (queue item `hover-tidy`) and the map's missing-method drift (queue item `docs-index`); the new map check refuses names that do not exist, not lists that lag.
- A semantic check of doc prose: the doc gate makes the change say why a document stays as it was, it cannot read whether the prose is true.

## Impact

- README.md: the `make gates` row and the list of what the gates refuse name the scenario gate and the doc prose refusals.
- docs/architecture.md: unchanged, the test and gate machinery of section 10 keeps its shape and the file is at its budget.
- CLAUDE.md: the Coding conventions name the scenario rule and the doc gate.

## Assumptions

- "Stale doc prose" cannot be judged by a machine; the accepted mechanical form is that a behavior change (a spec in the diff) or a process change must touch the document or record in its proposal why it stays, which puts the question before the quality review.
- A scenario counts as tested when its name appears, in any case, in a test file (a label or a comment); MODIFIED requirements are checked whole, since the change restates them.
- Exempting `Buffer#styles` with its owner is preferred to fixing it here, which would widen this tooling change into the documentation formatter.
