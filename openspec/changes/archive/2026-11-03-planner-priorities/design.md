# Design

## Context

The planner (`.claude/agents/planner.md`) writes `build/plan/queue.md`, which the contributor's package step copies over `docs/queue.md`. Its charter, `docs/goals.md`, is a priority list of fourteen goals with one rule for evidence. The run state records no estimate: the planner records nothing, and the workflow stores only measured figures (`metric.phase.*`, `metric.first.*`, `metric.rework`, `metric.ci_min`). `tools/run_state.sh history` writes a change's row in the next change's package step, from its run state and its squash commit (`merged`). Nothing parses `docs/queue.md`; `status` prints it.

## Goals / Non-Goals

Goals: the rubric written once, in the charter, with the planner applying it; every queue item tagged with a tier and a size that a check enforces; each history row carrying the estimate beside the actual output tokens; the retrospective flagging an overrun from one command's line.

Non-goals: a change to the workflow script; a budget per item other than the three sizes; checking the queue's prose beyond the two tags.

## Decisions

- The rubric lives in `docs/goals.md` under its own heading after the priorities, and `planner.md` points to it rather than repeating it, so the agent file stays small (it is read on every run) and the charter has one copy.
- The queue item format is the one the planner already writes in `build/plan/queue.md`: the parenthesis after the item's name holds a tier token `T0` to `T6` (several when tiers are folded, as `T3 with T6 folded`) and `estimated small`, `estimated medium`, or `estimated large`. A queue item is a line that starts with a number and a period; the bullets under "Under discussion" and "Decisions" are not items.
- The check is a `check_queue` function of `tools/docs_lint.sh` (gate `queue`), not a `tools_test` case alone, so it runs on the real `docs/queue.md` in `make docs-lint`, in `make check`, and in CI; `tools_test` cases prove it passes a tagged queue and fails an item without a tier or without a size. A tree without `docs/queue.md` passes. Alternatives: a `tools_test` case reading the repository's queue would test the data, not the tool, and run only in `tools-test`.
- `docs/queue.md` is replaced now by the planner's `build/plan/queue.md`, which the package step would copy anyway, because the check fails on the current queue (items 6, 10, and 12 have no size word). The package step copies the same file again, a no-op. `tools/gates.sh` keeps treating `docs/queue.md` as settled after the stages (a planning record the package step writes), so the package step itself runs `make docs-lint` before the push (`contributor.md`), and CI runs it again.
- The estimate is read from git, not recorded: `estimate_of` takes the item whose name is the change in `docs/queue.md` at the parent of the squash commit (`merged^`), the queue the change was delivered from, and prints its `estimated <size>` word, `-` when no item names the change or states a size. This needs no workflow change, works for a change already merged (this one included, whose item 1 says `estimated small`), and cannot be forged by an agent's metric line. `merged` is checked as a commit hash before it reaches git; the two older unchecked uses stay for `guard-hardening`, as planned. Alternative rejected: a `metric.estimate` recorded by the workflow at the plan phase, which needs a script change and misses the runs started before it.
- The history gains a 15th column, `estimate`, appended after `review` so no reader of a fixed column (`rates` reads 5 and 6, `bench_compare` 8 to 10, `review_due` 14) shifts. The actual stays column 11, `out_tokens`. The existing rows get `-`, since no estimate was made before this change; workflow-trim's row, appended in the package step, reads `-` too, because its queue item had no size word.
- `budget CHANGE` prints one line, `over: ...` or `within: ...` with the estimate, its budget, and the actual output tokens (the same sum `history_row` uses, now one function `out_tokens`), or `no estimate: ...`, and exits 0 in every case; the retrospective (read profile, which the guard allows `budget`) records `note CHANGE overrun "..."` on `over`. The budgets are one constant, `TOKEN_BUDGETS`, with the numbers of `docs/goals.md`.
- `CLAUDE.md` stays within its 30,720-byte budget by naming the tiers of agent models once ("the others on the session's model") instead of listing the four agents again.

## Risks / Trade-offs

- A queue item renamed between plan and merge loses its estimate (`-`); the planner keeps an item's name, and the column is a record, not a gate.
- A planner that writes a malformed queue is caught in the package step and CI, not by the checker, because the queue is copied after the checks; the push is refused by nothing in between. The package step's `make docs-lint` closes that gap.
