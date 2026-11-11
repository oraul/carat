# Tasks

## 1. CI scope

- [x] 1.1 `tools/ci_scope.sh` counts `.claude/agents/`, `.claude/workflows/`, and `.claude/settings.json` as code. Proved by `tools/tools_test.sh` "ci_scope: .claude/agents/x.md on a pull request", "ci_scope: .claude/workflows/x.js on a pull request", "ci_scope: .claude/settings.json on a pull request" (run=true) and "ci_scope: .claude/commands/x.md on a pull request" (run=false).
- [x] 1.2 `tools/ci_scope.sh` skips a pull request whose changes since its last green head are documentation; `.github/workflows/ci.yml` passes `PR` and `HEAD_SHA`. Proved by "ci_scope: documentation since the last green head skips", "ci_scope: code since the last green head runs", and "ci_scope: no green head runs", and "ci_scope: the head itself is never the green head".

## 2. Run state

- [x] 2.1 `tools/run_state.sh ci-stages`. Proved by "run_state: ci-stages records each step's seconds", "run_state: ci-stages names a step by its words, cut at 32 characters", "run_state: ci-stages refuses a commit that is not full", "run_state: ci-stages replaces the previous run's stages", and "run_state: ci-stages records nothing and passes without a run".
- [x] 2.2 `tools/run_state.sh tokens` with `TIER_PRICES`. Proved by "run_state: tokens records each start", "run_state: tokens counts a repeated message once", "run_state: tokens weighs the cheap tier by its price", "run_state: tokens counts a directory once", "run_state: tokens adds a later run's starts", "run_state: tokens sums the phase", and "run_state: tokens refuses a missing directory".
- [x] 2.3 `tools/run_state.sh` history columns 19 to 22 and `docs/metrics.tsv` padded. Proved by "run_state: history records the CI stages, waiting calls, and weighted tokens" and "run_state: every history row has the header's columns".

## 3. Guard and workflow

- [x] 3.1 `tools/agent_guard.sh` close profile runs `ci-stages` at a full sha; `.claude/workflows/deliver-change.js` queues it when the merger reads green or red (`CLOSABLE`) and records `ci_wait_calls` (`waitsOf`, which `mergerCap` uses). Proved by "guard: close records the CI stages", "guard: close refuses CI stages at a short commit", "guard: read refuses the CI stages", "guard: merger refuses the CI stages", "workflow: the closing start records the CI stages at a full commit only", "workflow: the merger's waits come from its minutes, its cap from the waits beyond the second", "workflow: the merger's waiting calls are recorded", and "workflow: the merger's lines leave the CI stages to the record and closing starts".
- [x] 3.2 `.claude/commands/deliver.md` runs `tokens` after each start. Proved by "deliver: the command records the weighted tokens".

## 4. Docs

- [x] 4.1 CLAUDE.md Commands, README's measurement paragraph, `docs/architecture.md` section 10, `docs/codebase-map.md`, the script header. Proved by `make gates` and `make docs-lint`.
