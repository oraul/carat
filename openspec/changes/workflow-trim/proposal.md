# Proposal

## Why

About 300k output tokens of every change are fixed overhead of the delivery workflow, and part of it buys nothing: scouts took 46%, 58%, and 57% (211k) of the output tokens of the last three measured runs, 3.5 times the implement phase of `plugin-path-containment` (59k of 373k), with packs answering backlog-only questions; the benchmark agent recorded 0 tool calls in 3 of 3 runs while allocations and rounds never changed; a test-only fix round reran all 13 stages (about 196 s). The workflow also corrupts its own figures and stalls: the CI watcher stopped while CI was still running in 3 runs (`window-navigation-and-scroll`, `untrusted-config-limits`, `agent-authority`), each needing a manual resume; resumed runs recorded `first_pass` `ci:1` only and phase figures for 2 of 11 or 12 phases, because the figures lived in the script's memory; and the reporter cannot record its phase, since `report` is not a phase name. The user moved this change to the front of the queue (tier T1 plus T4).

## What Changes

- Scouts: the scout plan lists only the map areas whose files the brief says the change edits, at most three; the planner returns plan notes (findings the change only records in `docs/backlog.md`, bookkeeping) that the workflow hands to the contributor, never to a scout.
- One agent for CI and the merge: the `ci-watcher` agent is removed and the `merger` waits for CI's conclusion at the pushed head with backoff, never returning while a check is queued or in progress before its wait limit; the workflow calls it again while CI is pending, up to a generous total, then stops with the exact state of every check. A red CI goes back to the contributor's fix loop as before. The merger takes the pull request body from `build/pipeline/<change>.body.md`, which the contributor's package step writes, instead of rereading the pull request.
- The benchmark: a new `tools/run_state.sh bench CHANGE` imports the `metrics` stage's measurement, runs `make metrics-compare` against main's figures (the run state of the newest merged change without a `docs/metrics.tsv` row, else the last row), and exits 0 when allocations and rounds equal them; the checker runs it after the stages, and the workflow records the benchmark review from that result. The benchmark agent runs only when they differ, with `PREFIX` and `SPINEL_CACHE_DIR` given for the base build.
- Figures in the run state: each phase's output tokens and tool calls are stored as `metric.phase.<name>` as the phase ends, each gate's first verdict as `metric.first.<gate>`, the rework rounds and CI minutes as they change; a resumed run seeds its figures from them. `tool_calls` is a required field of every agent result. `history` builds a row's first passes from those lines, filling a gate without one from the run state's `stage.*`, `review.*`, and `ci` lines, and its token and call totals and phase figures from `metric.phase.*`, so every row is whole; the retrospective and the reporter no longer run a metric command line.
- Test-only fix rounds: `tools/run_state.sh check` carries a stage other than `test-build`, `test-run`, `diagnose` (which analyzes the test runner), `metrics` (which reads the runner's rounds), `docs-lint` (which reads `docs/*.md` and the `test/` paths they name), and `gates` that passed at a commit from which only files under `test/` (and the OpenSpec and planning records, which no carried stage reads) changed, recording it at `HEAD` with the commit it was carried from; the quality reviewer of such a round gets the fix diff and the prior blocking findings.
- `report` is a phase name; the workflow records it after the reporter.
- The record queue is flushed after the verification rounds (the pre-push gates read the reviews), once after the package step, once after the merge, and once at the end, instead of after every phase.
- `tools/tools_test.sh` cases for every `tools/run_state.sh` and `tools/agent_guard.sh` change; `CLAUDE.md`, `README.md`, the code map, and `docs/backlog.md` (the entries "The ci-watcher and the merger read the same pull request state twice" and "CI took 12 minutes at untrusted-config-limits" removed).

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None. This is a change to the delivery workflow, its agents, and its scripts, with no change to the editor's behavior; `skip_specs` is set.

## Impact

- Removed: `.claude/agents/ci-watcher.md`.
- Changed: `.claude/workflows/deliver-change.js`, the agents `merger`, `checker`, `benchmark`, `quality-reviewer`, `planner`, `retrospective`, `reporter`, and `contributor`, `tools/run_state.sh`, `tools/agent_guard.sh`, `tools/tools_test.sh`, `Makefile` and `.github/workflows/ci.yml` (comments only), `CLAUDE.md`, `README.md`, `docs/codebase-map.md`, `docs/backlog.md`.
- No file under `carat/`, `bin/`, `test/`, or `bench/` changes; the editor binary is unchanged.

This change is outside the roadmap of `docs/architecture.md` section 12: it trims and repairs the delivery pipeline, by the user's decision and goals 2 and 13 of `docs/goals.md`.

Out of scope: the planner's rubric (`planner-priorities`, next in the queue); the queue reorder the brief asks of the planner, which the planner wrote to `build/plan/queue.md` and the package step commits; the records gate passing a merge given no records, which waits for `pipeline-hardening`; a dry run of the new workflow, which can only run on the next change (the running workflow loaded the old script), so the before and after figures are the next run's history row against this one's.

Assumptions recorded instead of asked:

- The review records must reach the run state before the push, whose pre-push gates read them, so the flush at the end of the verification rounds stays beside the two the brief names, and one more at the end of the run records the retrospective's, the report's, and a stopped run's records.
- "Report stalled with the exact state" is done by the workflow: the merger returns `pending` with each check's name and state when its own wait limit passes, and the workflow calls it again up to four times (about two hours of waiting) before it stops with that state, so no single agent has to stay alive for the whole wait.
- The body file is written by the contributor's package step, so the contributor's guard profile allows `build/pipeline/<change>.body.md`, the one file of the run state's directory the merger profile already allows; both profiles refuse a path that continues past that file name.
- On a test-only round the `metrics` stage runs again, since it reads the test runner's rounds from `test-build`'s report; it only measures the earlier stages' builds, so it costs little.
- Seeding from `stage.*` lines reads a check whose stages all passed as a first pass, which a run that failed and was fixed before a crash overstates; `metric.first.*`, written as each verdict happens, takes precedence, so only run states from before this change are derived that way.
