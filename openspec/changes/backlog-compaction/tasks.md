# Tasks

## 1. Merge the backlog's duplicates

- [x] 1.1 `docs/backlog.md`: merge each set of entries recording the same finding into its earliest entry, with a `Raised again as` bullet per merged entry, and move the duplicated clauses of the two grouped entries to their standalone entries. Checked by `make docs-lint` and a count of headings before and after.

## 2. The append-only rule

- [x] 2.1 CLAUDE.md (Agents section, the backlog coding-conventions line) and README.md (the planner and package steps): during a delivery no agent reads `docs/backlog.md`; findings are appended; upkeep is the periodic review's. Checked by `make gates` and `make docs-lint`.
- [x] 2.2 `.claude/agents/contributor.md`, `planner.md`, `quality-reviewer.md`, `security-reviewer.md`, `retrospective.md`: the contributor appends by a shell append without reading and removes nothing; the planner never reads the backlog; the periodic quality review reports fixed, duplicated, and gone-code entries. Checked by `make docs-lint` (the agent file budget) and `make tools-test`.
- [x] 2.3 `.claude/workflows/deliver-change.js`, `.claude/commands/plan.md`, `.claude/commands/review.md`: the prompts hand findings to append and no longer say the planner reads the backlog. Checked by `make tools-test` and `make gates`.
- [x] 2.4 CLAUDE.md, `.claude/agents/contributor.md`, `planner.md`, the scout prompt of `.claude/workflows/deliver-change.js`, README.md, and the `docs/backlog.md` header: a contributor or scout whose queue item names backlog entries greps the file for those entries only; deliveries only append and the periodic review merges and removes entries. Checked by `make gates` and `make docs-lint`.
