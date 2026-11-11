# Tasks

## 1. Run state

- [x] 1.1 `tools/run_state.sh` `review-due`: sprint counting from `docs/sprints.tsv` (new, seeded with sprint 0), the sweep in even sprints, not due while the plan waits; REVIEW_AREAS, `keymap_only`, and `agent_hooks` removed. Proved by `tools/tools_test.sh` "run_state: review-due is not due before the fifth merge of the sprint, a review run not counted", "run_state: review-due is due at the fifth merge with the combined diff", "run_state: review-due asks for the sweep in an even sprint", and "run_state: review-due is not due while the sprint plan waits".
- [x] 1.2 `tools/run_state.sh` `backlog-dups` and `groom`. Proved by "run_state: backlog-dups names entries at one location", "run_state: groom removes a merged item's listed headings and no others", "run_state: groom keeps a disputed security entry", "run_state: groom keeps the first of a repeated heading", "run_state: groom refuses a duplicate alone at its location", "run_state: groom removes a security entry with its fixing commit", "run_state: groom refuses an unknown heading and writes nothing", and "run_state: groom appends the sprint row".
- [x] 1.3 `tools/run_state.sh` `plan-needed` reads the waiting sprint's queue. Proved by "run_state: plan-needed reads a waiting sprint plan".

## 2. Guard and lint

- [x] 2.1 `tools/agent_guard.sh`: the read profile runs `backlog-dups`, the contributor `groom`. Proved by "guard: the read profile lists backlog duplicates" and "guard: the contributor applies the sprint plan".
- [x] 2.2 `tools/docs_lint.sh` queue check: a sprint of 0 to 5 items with at most one pipeline item, T0 exempt. Proved by "docs_lint: a sprint of six items fails", "docs_lint: a drained sprint of 0 items waits for /sprint", "docs_lint: a sprint with two pipeline items fails", and "docs_lint: a T0 pipeline item does not count".

## 3. Workflows

- [x] 3.1 `.claude/workflows/sprint-planning.js` and `.claude/commands/sprint.md`: the phases, not due ending at once. Proved by "sprint: not due ends before any reviewer start", "sprint: the diff reviewers record nothing and the skeptic records the kept findings", "sprint: the sweep runs in an even sprint", and "sprint: a due line naming a shell word is not due".
- [x] 3.2 `.claude/workflows/deliver-change.js`: no periodic review, the close says when sprint-planning is due; the scouts' grep exception removed. Proved by "workflow: the delivery never starts the periodic review" and "agents: no delivery reads or greps the backlog".

## 4. Agents and docs

- [x] 4.1 `.claude/agents/planner.md` (self-contained items, sprint mode), `contributor.md` (groom, append only), `quality-reviewer.md` (sprint and skeptic modes), `security-reviewer.md` (sprint mode), `retrospective.md` (review-due without a change). Proved by "agents: no delivery reads or greps the backlog" and "agents: the planner writes self-contained items".
- [x] 4.2 CLAUDE.md, README.md, `docs/goals.md`, `docs/codebase-map.md`, `.claude/workflows/periodic-review.js` header, `.claude/commands/review.md`. Checked by `make gates` and `make docs-lint`.

## 5. Review fixes

- [x] 5.1 A sprint never closes without its security review: `sprint-planning.js` starts the planner only after the security review and the skeptic returned, and `review-due` stays due and `groom` holds the plan while `sprint-N` records no pass or blocked security review. Proved by "sprint: the planner starts only after the security review and the skeptic", "run_state: review-due stays due while the waiting plan's sprint has no security review", "run_state: review-due stays due while the sprint's security review did not run", "run_state: groom holds a plan whose sprint has no security review", and "run_state: groom holds a plan whose sprint security review is partial".
- [x] 5.2 The sprint findings the planner does not queue go into `build/plan/groomed.md`, which `groom` appends and a delivery's planner keeps, never `build/plan/backlog.md`. Proved by "agents: the sprint planner keeps unqueued findings in groomed.md" and "run_state: groom removes a merged item's listed headings and no others".
