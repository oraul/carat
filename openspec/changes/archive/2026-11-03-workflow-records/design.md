# Design

## Context

The scout pack `tmp/scout/build-and-ci-05e2a4c-20261103T221713Z.md` (Commit: 05e2a4c, `origin/main`) holds: the advisories reach the script as strings and leave it as a count (`deliver-change.js` quality branch, `run_state.sh review`); the merger's schedule waits 510 seconds in all through a background `sleep`; `flush()` takes the pending figures before starting its own record agent, so that agent's cost lags one flush and the last one is never written; `estimate_of` reads only the queue at the squash commit's parent. Every finding was re-checked against `main` and still holds.

## Decisions

### Advisories: a note per advisory and the package step's backlog list

The reviewer already records each blocking finding as a `quality-blocking` note with its commit; it now records each advisory the same way as `quality-advisory`. The workflow keeps `qualityAdvisory`, the last review's list, and `seed()` rebuilds it from the notes at `review.quality`'s commit when their number equals the review's `advisory=N`, as it does for the blocking ones. The package step receives them with the non-blocking security findings, prefixed `quality advisory`, and `contributor.md` already puts every such finding into `docs/backlog.md`. The advisory text never enters a shell command the workflow builds: the reviewer writes its own notes, so a finding's text cannot change a record line.

### CI wait: a foreground wait script

The merger may not run `gh`, and no script may name a link, so CI is read only through the GitHub tool; the wait between reads is what must hold the merger's turn. A background `sleep` ends a subagent's turn, so the merger returned `pending` after a few minutes. `tools/ci_wait.sh SECONDS` sleeps in the foreground, refusing anything but a whole number from 1 to 540 (under the shell tool's 600-second limit). The schedule is 30, 60, 120, then 300 seconds repeated, until 30 minutes since the first read: a 3-minute CI run costs four reads and three waits. `MERGE` gains `waited` (minutes); the workflow notes a `pending` returned before 30 minutes, the measure of the acceptance. `WAITS` stays as the stall guard for CI runs over 30 minutes.

### Records: two record starts, figures in metric lines

Phase and review lines need the record agent (the guard keeps every other agent off them). The pre-push gates read the reviews, so the flush at the end of `verify()` stays; the final flush stays for the retrospective's and the report's phases. The flushes after the package step and after the merge go:

- the package, CI, and merge phase lines wait in the queue for the final flush;
- a resume treats the package step as done when the run state holds `pushed` and `pr` (both written by the package step itself: `run_state.sh push` and `set pr`), instead of `phase.package`;
- a resume after the merge is already decided by `merged`, which the merger writes.

`flush()` starts an agent only when a phase or review line waits; figures alone ride with the next agent already started.

### Figures: one snapshot line

`figure()` and its change map go. `metricLine()` builds one `sh tools/run_state.sh metric CHANGE ...` line from every figure the workflow holds: `phase.KEY=TOKENS/CALLS` for every phase, `first.GATE`, `rework`, `ci_min`, and `estimate`, each pair matched against fixed names and numeric or size-word values. Every flush appends it, and the merger and the retrospective run it first (`metric` is allowed to both profiles). The retrospective's prompt builds the line and `summary()` together, so after its first step the run state's totals equal the prompt's. The final flush's line holds every figure through the report; its own record start comes after every line and is the one cost recorded nowhere, by construction.

### Estimate: stored at plan time

`PLAN` gains `estimate` (small, medium, or large), the size the planner gave the change. The workflow stores it with the figures as `metric.estimate` and seeds it on resume. `estimate_of` returns `metric.estimate` when it is one of the three words, and otherwise reads the queue at the squash commit's parent as before, so older run states keep their estimate. `budget` then works for a change whose item the planner removed, and before the merge too.

## Risks

- A merger that runs `ci_wait.sh` with a longer timeout than its default spends the same time; the 540 cap keeps each call under the tool's limit.
- A workflow killed between the package step and the final flush loses `phase.package`, `phase.ci`, and `phase.merge`; the resume reads `pushed`, `pr`, and `merged` instead, so no step repeats.

## Verification

`tools/tools_test.sh` covers `ci_wait.sh` (a wait, and the refusals) and the stored estimate (`budget` and the history row of a change with no queue item, and the stored estimate winning over the queue's). The workflow cannot run inside its own delivery: `node --check` parses it, and the next delivery's run state shows the two record starts and equal totals.
