# Design

## Context

`.claude/workflows/deliver-change.js` starts each agent with a schema and stops the run on a null result or a result that is not `done` (`contributor()`, `reviews()`). A start that reaches its agent file's `maxTurns` returns nothing, and one that stops at its stated cap returns `stopped`, so both end the run although a contributor commits and backs up as it goes. `.claude/workflows/periodic-review.js` gives the quality reviewer the whole tree in one start of 53 calls; the reviewer reads the files of the last five changes and samples the rest, reporting the areas it skipped. The merger is told the 12-character head of the contributor's result, and `tools/run_state.sh push` records the same short form.

## Goals / Non-Goals

Goals: an unfinished start is continued from what it left instead of failing the run; the periodic quality review covers every map area and records it; the merger passes the full pushed sha and fits its cap on a first green. Non-goals: changing the runtime's ceiling, the security review's areas, or the merger's guard forms.

## Decisions

### Continuations

One pure helper decides what follows a start: `continuation(result, rest, count)` returns `done` when a result left nothing, `stop` when a result stopped on its own (a contributor's question), and otherwise `continue` with what is left while `count` is under `CONTINUES` (2), `stop` after. `rest` comes from the kind: `workLeft` reads a contributor's `status` and `remaining`, `reviewLeft` a review's `not_reviewed` (the whole diff for a security review with `ran` false). A null result, a start at its turn ceiling, is continued with nothing named, so the next start reads the branch and `tasks.md`. Each continued start is measured under the same key and leaves a note of fixed words for the planner. The alternative, raising `maxTurns`, only moves the ceiling.

The reviews merge a continuation's findings into the first start's (`combineReviews`, without duplicates); the security retry of a result with `ran` false becomes the first continuation, so the review still runs at most three times and a security review with anything left still stops the run, never passes.

### The periodic quality review by area

`MAP_AREAS` (18) is the count of numbered areas of `docs/codebase-map.md`, which a `tools/tools_test.sh` case compares with the map; `areaSlices(MAP_AREAS, QUALITY_SLICES)` splits them into three runs of consecutive areas. Each start names its areas and its worktree `tmp/.review-quality-N`, so the parallel starts do not share one; the quality reviewer reads every area it is given. The areas a start reports in `not_reviewed`, kept to its own slice, or the whole slice when it returned nothing, get one more start. The record's summary carries `covered=N/18`, and `partial` with `not_reviewed=` only when an area is still left after the continuation. Three starts of 53 calls hold about 18 calls per area against the 8 or so a single start managed.

### The merger's head and cap

`push_branch` records `git rev-parse HEAD`, the full sha (`set pushed` and `gates.sh` already accept 7 to 40 digits and resolve either). The package and push starts return it as `pushed`; `pushedHead(pushed, head)` keeps it only when it is 40 digits beginning with the reported head, and the merge loop stops before any merger start when it is not. The merger compares the full sha with the pull request's head and passes it as the expected head, which closes both backlog entries on the merger's head: GitHub gets the full sha, and the head the reviews covered is the one pushed.

The branch deletion of step 7 becomes a counted call, so a first green is seven calls and two for each wait; `FIXED_CAPS.merger` is 12 (seven calls, two waits, one spare). The ceiling counts the waits once: of the seven waits of 30 minutes the cap holds two, so `maxTurns` is 12 + 2 x 5 + 5 = 27, and the test and the comments say so.

## Risks / Trade-offs

- A continued start costs its fixed overhead again; two continuations bound it, and a start that fails three times still stops the run with a resumable state.
- `tools/tools_test.sh` now runs the workflow's helpers with `node`, extracted by name; a helper renamed without its test fails the case, which is the intent.
- The guard of this change's own merge is `main`'s copy; no guard form changes, so the merge runs under it unchanged.
