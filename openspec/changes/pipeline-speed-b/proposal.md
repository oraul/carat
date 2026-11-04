# Proposal

## Why

The review loop costs more rounds than the findings need, and the merge trusts a head no gate it can rely on checked. Quality and security run one after the other and a round that quality blocks skips security, so `guard-allowlist` reworked 5 times (quality 321,350 and security 111,551 output tokens, 42.4% and 14.7% of the run) and `guard-hardening` 2 times. A fix round re-reviews the whole branch, so `buffer-search` spent 102,654 output tokens on quality (52.3% of 196,375) where round 2 found nothing blocking. The checker skips a stage record at the head whoever wrote it (periodic security Low (5), `tools/run_state.sh:262`), and the merger runs the branch's own `tools/gates.sh` and `tools/run_state.sh` (periodic security Medium (7), `.claude/agents/merger.md:22`). This is item 1 of `docs/queue.md`, part B of `pipeline-speed`, outside the editor roadmap of `docs/architecture.md` section 12: it changes the delivery workflow only.

## What Changes

- (a) Reviews: the quality and the security reviewer run in parallel on the same commit, after the check passes, and their blocking findings go back to the contributor in one fix round, the security findings first.
- (b) Re-review scope: a fix round's quality review covers only `git diff <reviewed commit> HEAD` and the prior findings when `sh tools/run_state.sh scope CHANGE COMMIT FILE...` finds that the fix changed only the files the blocking findings name, tests, and the OpenSpec and planning records; otherwise the whole branch diff. The security review keeps reviewing the whole committed diff.
- (c) Check: `sh tools/run_state.sh check CHANGE [COMMIT]` counts a stage record only at COMMIT, the last commit whose check the workflow recorded, which the workflow passes; a record at the head no workflow record backs is run again. The workflow records `phase.check` itself, `tools/gates.sh stages` requires every stage at the commit of `phase.check`, and the merge's records gate compares `phase.check` with the workflow's `check:pass:COMMIT`.
- (d) Merge integrity: the workflow gives the merger a command that adds a fresh worktree of `origin/main` at `tmp/.merge-gates` and runs that copy's `tools/gates.sh merge`; the merge group adds the stages gate, the records gate requires the security record, the passed gate refuses a dirty tracked tree, and the merger squash-merges with the local head the gates checked as the expected head. The guard admits the merger's gates only from `tmp/.merge-gates`.
- Folds: an advisory repeated at a later round is one note and one backlog entry (`run_state.sh note` and `addAdvisories` key on the text without its commit); `priorQuality`'s local `findings` no longer shadows the module function.
- The brief's scratch-file request (stray `build_check_out_tmp` and `.err` in the repository root) is recorded in `docs/backlog.md`, queued in `pipeline-speed-c`, not fixed here, as the planner decided.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None: the change touches the delivery workflow, its agents, and its scripts, and no editor behavior, so it sets `skip_specs: true`.

## Impact

- `.claude/workflows/deliver-change.js`, `.claude/agents/checker.md`, `quality-reviewer.md`, `merger.md`.
- `tools/run_state.sh` (`check`, `scope`, `note`), `tools/gates.sh` (`stages`, `records`, `passed`, `merge`), `tools/agent_guard.sh` (the merger's gates, the reviewers' `scope`), `tools/tools_test.sh`.
- `README.md`, `docs/codebase-map.md`, `docs/backlog.md`.

## Out of scope

- Narrowing the security review: the hard rule asks for a security review of the change's committed diff, so it reviews the whole branch in every round.
- The scratch-file gate and the agents' scratch directory (`pipeline-speed-c`), the resume and status items queued there, and the `CLAUDE.md` items queued in `docs-currency`.

## Assumptions

- The parallel reviews' output tokens are counted under one phase key, `reviews`, since the runtime counts the output tokens of the whole run and cannot split two concurrent agents; their tool calls are added to the same key. A round that runs one review keeps its own key.
- The workflow that delivers this change is `main`'s copy, which does not record `phase.check` or pass `check` in `RECORDS`, so `check` keeps writing `phase.check` beside the workflow's record and the records gate compares only the kinds it is given; the next run uses the new workflow and the new gates on `main`.
