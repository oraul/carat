# Tasks

## 1. Clearing rule

- [ ] 1.1 Make `merged_since` in `tools/run_state.sh` clear a failing periodic security review only for a merged change whose `phase.plan` strictly descends from the reviewed commit and whose `metric.planned` is not `0`, the newest history row's change name checked first; proved by "run_state: plan-needed keeps a failing periodic security review a merge planned before it followed", "run_state: plan-needed keeps a failing periodic security review a merge with a skipped planner followed", and "run_state: plan-needed leaves a failing periodic security review a later merge followed" in `tools/tools_test.sh`

## 2. Docs

- [ ] 2.1 Update the `plan-needed` header line and the `merged_since` comment of `tools/run_state.sh`, the comment above `planReview` in `.claude/workflows/deliver-change.js`, the README pipeline step 1, and the map's `tools/run_state.sh` entry; checked by `make docs-lint` and `make gates`
- [ ] 2.2 Run `make tools-test` (seconds compared with the run before the change), `make docs-lint`, `make gates`, and `make spec-validate`
