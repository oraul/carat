# Proposal

## Why

The delivery workflow treats a start that ends unfinished as a failure. The first `lsp-diagnostics` contributor start reached its turn ceiling at 10 of 11 tasks and returned nothing, so the run stopped although its work was committed and backed up. The whole-tree periodic quality review is one start at a fixed cap over 18 map areas, and it came back partial three times in a row (11, 9, and 12 areas not reviewed), so no review has covered the tree. The merger passes the 12-character pushed head as GitHub's expected head, which GitHub matches against the full sha, and its first-green path went over the cap of 10 calls in each of the last four runs (11, 11, 12, 13), the uncounted branch deletion and a refused merge among the extra calls.

This change is outside the roadmap of `docs/architecture.md` section 12: it repairs the delivery pipeline (`docs/queue.md` items 1 and 2, `merger-head` folded into `partial-results`).

## What Changes

- A contributor start may return `partial` with `remaining`, the tasks or steps it left at its cap; the workflow continues a partial start, and a start that returned nothing (its turn ceiling), with another start told what is left, at most twice in a row, before it stops the run.
- The quality and security reviews of the diff return `not_reviewed`, the files they did not cover at the cap; the workflow continues a review that left files or returned nothing over what it left, merging the findings, and a security review never passes while anything is left.
- The periodic quality review is split over the map's 18 areas in three parallel starts, each with its own worktree, and an area a start did not cover is continued once; the record says `covered=N/18`, `partial` only when an area is still left.
- `tools/run_state.sh push` records the full sha as `pushed`; the package and push starts return it, the workflow checks it begins with the reported head and passes it to the merger, which compares it with the pull request's head and passes it as the expected head.
- The merger's branch deletion is a counted call, its first-green cap is 12 (seven calls and two waits, one spare), and its turn ceiling is the cap, two calls for each of the five later waits, and the margin.

## Capabilities

### New Capabilities

None: the change alters the delivery tooling, not the editor's behavior (`skip_specs: true`).

### Modified Capabilities

None.

## Impact

`.claude/workflows/deliver-change.js`, `.claude/workflows/periodic-review.js`, `.claude/agents/contributor.md`, `merger.md`, `quality-reviewer.md`, `security-reviewer.md`, `tools/run_state.sh` (`push`), `tools/tools_test.sh`, `CLAUDE.md`, `README.md`, `docs/codebase-map.md` area 1, and `docs/backlog.md`.

## Out of scope

- The runtime's turn ceiling itself: a start at `maxTurns` still returns nothing; the workflow now continues it.
- `review-due` reading the periodic quality result: a partial quality review still does not keep the next review due (the security result does).
- Folding the merger's fetch and record calls into one: it needs a new merger form in `tools/agent_guard.sh`, which the merge of this change itself would run from `main`'s older copy.

## Assumptions

- A continued start resumes from the branch's commits and backups and from `tasks.md`, which every contributor start already writes as it goes; two continuations in a row bound the extra cost.
- `node`, which `make doctor` already requires for OpenSpec, runs the workflow's pure helpers in `tools/tools_test.sh`; the GitHub runner has it.
- The merger's 11 to 13 calls came from the uncounted branch deletion and the retry of a merge refused for its short head; a cap of 12 holds a first green with the deletion when CI passes within two waits.
