# Design

## Context

`.claude/workflows/deliver-change.js` `rounds()` ran check, quality, security, and bench in order at the head, each skipped when its record is already at the head, and handed the first blocking result to the contributor. `priorQuality()` offered the quality reviewer the fix diff only when every changed file was under `test/`. `tools/run_state.sh check` skipped a stage recorded as passed at the head whoever wrote the record. The merger ran the merge gates from the branch's working tree. The scout pack `tmp/scout/build-and-ci-c62941c-20261104T064812Z.md` holds the line references; they still hold at c62941c.

## Goals / Non-Goals

Goals: one fix round per commit for both reviews; a fix round reviewed at the size of the fix; a check record that counts only when the workflow backs it; a merge whose gates the branch cannot have edited. Non-goals: narrowing the security review, the scratch-file gate, the resume items of `pipeline-speed-c`.

## Decisions

### (a) Parallel reviews

After the check passes, `rounds()` builds the reviews not yet passed at the head and runs them with `parallel()`, both on the same commit, then collects the blocking findings of both into one message, security first, for one `contributor('fix', ...)`. The security retry (a review that did not complete) runs after the pair, alone. Each agent call names its progress group with `opts.phase`, since `phase()` is global. Two concurrent agents cannot have their output tokens told apart (`budget.spent()` counts the whole run), so a round with both reviews records them under the phase key `reviews`, tokens and both reviewers' tool calls; a round with one review keeps its own key. Only the quality reviewer writes the run state during the pair (its notes); the security reviewer in diff mode records nothing, so no two writers race on `build/pipeline/CHANGE.json`.

### (b) Re-review scope

When a round blocks after both reviews ran at commit C, the workflow keeps the files the blocking findings name: the `file` of each security finding and the path before `:LINE` of each quality finding (the reviewer's `<commit> <file>:<line> ...` form), each a plain relative path (`[A-Za-z0-9_][A-Za-z0-9_./-]*`, no `..`). A finding without one leaves the files unknown. A resume rebuilds them from the quality-blocking notes when the security review passed at C. The next quality review at a later head gets, when the files are known, `sh tools/run_state.sh scope CHANGE C FILE...`: it prints `fix: ...` and exits 0 when every path changed from C to HEAD, without rename detection, is one of the files or matches `TEST_ONLY` (tests, `openspec/`, and the planning records), and `branch: PATH ...` with exit 1 otherwise or when nothing changed. On `fix` the reviewer reviews `git diff C HEAD` against the prior findings and the rules; otherwise the whole branch diff. The comparison is the script's, not the reviewer's reading, and `tools/tools_test.sh` covers it. The guard adds `scope` to the read profile's run-state verbs.

The security review is not narrowed: the hard rule asks for a review of the committed diff, and the security reviewer's skill reviews the branch against `origin/HEAD`.

### (c) Check records the workflow backs

`check CHANGE [COMMIT]`: a stage record counts only when its commit is COMMIT, which the workflow passes as the last commit its own `phase.check` names. A record at COMMIT equal to HEAD is skipped; one at COMMIT before a test-only change is carried for a stage outside `TEST_STAGES`; every other stage runs, so a record written at the head by anyone else is run again. Without COMMIT every stage runs. A checker killed midway therefore repeats its passed stages, the price of not trusting a record nobody backs.

The workflow skips the checker when its `phase.check` is the head, records `phase.check` from the checker's result (`phaseDone`), and passes `check:pass:COMMIT` in `RECORDS`. `gates.sh records` compares a `check` record with `phase.check`; `gates.sh stages` requires `phase.check`, settled at HEAD, and every stage passed at exactly that commit. `check` keeps writing `phase.check` itself, the same value, because the workflow that delivers this change is `main`'s copy, which does not record it; the merge's records gate is what ties it to the workflow.

### (d) Merge gates from `origin/main`

`mergeGates()` returns `git worktree remove --force tmp/.merge-gates; git worktree add -q --detach tmp/.merge-gates origin/main && CHANGE=... RECORDS="..." sh tmp/.merge-gates/tools/gates.sh merge build/pipeline/CHANGE.body.md`. The remove drops an earlier copy; the add fails when anything else stands at the path (a directory or a link the contributor left), so the gates do not run and the merge stops. That copy's `gates.sh` sources its own `rules.sh` and runs its own `run_state.sh`, from `$here`, against the branch's repository and run state in the working directory. The merge group gains `stages`, whose stage list is read from that copy's `Makefile` line `CHECK_STAGES :=` rather than by running the branch's `make`. `records` requires a security record; `passed` refuses a tracked file that differs from HEAD. The merger's step 5 passes the local HEAD the gates checked as the expected head, so GitHub refuses any other pull request head.

The guard's merger profile admits `sh tmp/.merge-gates/tools/gates.sh merge BODY` with `CHANGE` and `RECORDS`, and no longer `sh tools/gates.sh merge`. The hooks run `origin/main`'s guard, so this run's merger, with `main`'s workflow and its branch-copy command, is judged by the old guard; the next run's by the new one.

### Folds

`run_state.sh note CHANGE quality-advisory TEXT` records nothing when a `quality-advisory` note already holds TEXT after its leading commit, and says so. `addAdvisories` strips a leading commit from each advisory, so the reviewer's text and the seeded notes key on the same words. `priorQuality`'s local list is renamed `listed`.

### Agent files and the running workflow

The harness may read an agent's file from the branch while `main`'s workflow drives it, so each edited brief works with both prompts: the checker passes a commit only when its input names one; the quality reviewer follows the scope instruction its input gives; the merger runs the merge-gates command exactly as given.

## Risks / Trade-offs

- Two reviewers in parallel spend both reviews' tokens on a round that one of them blocks; the saving is the round it no longer takes.
- A quality reviewer given `fix` reviews less of the branch; the fallback to the whole branch whenever the fix reaches another file bounds what it can miss, and the security review still reads everything.
- The merge gates of `origin/main` lag a change that edits them until it merges, which is the point; a gate a change adds checks the next change.
