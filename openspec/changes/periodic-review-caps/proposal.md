# Proposal

## Why

`run-budgets` gave every start of the delivery workflow a stated tool-call cap and sized the reviewers' `maxTurns` from the diff-review cap, but the periodic review's starts state none (`.claude/workflows/periodic-review.js`, the task line and the security retry). A whole-tree review is never told to stop and return its schema, so it can reach the platform's `maxTurns` ceiling and end with nothing recorded, and a security review that ends without a result is recorded nowhere: the review-due count treats it as waiting, and nothing tells a reader it did not run. `README.md` and `CLAUDE.md` already say every agent start is told its cap. This is the periodic quality review's blocking finding at `f3b26da`, a T1 pipeline defect at the head of `docs/queue.md`, outside the editor roadmap of `docs/architecture.md` section 12: it changes the delivery workflow, its agents, and its scripts only.

It also restores a regression check `leader-layout` weakened: the lone-prefix timeout check of `test/editor_normal.rb` lost two of its three waits, a quality advisory in `docs/backlog.md`.

## What Changes

- The periodic review states a fixed cap in every start: `PERIODIC_CAP` (53) for each reviewer start and its retry, the large diff-review cap, which leaves the return margin of 5 under the reviewers' `maxTurns` of 58, and the record cap (3) for its record start. `tools/tools_test.sh` checks the cap and the margin against both agent files.
- The periodic schemas gain a required `not_reviewed` list: the security areas of the security reviewer's step 3 by fixed names, and the quality reviewer's map areas by number. A reviewer at its cap stops, lists what it did not cover, and returns.
- `tools/run_state.sh review` takes two more results for the periodic kinds only: `partial` (a result with areas not reviewed, named in the summary) and `not-run` (no result); neither records a phase, and the diff kinds still take only `pass` or `blocked`.
- A periodic security review that returns no result, or one whose head is not a commit, is retried once; when the retry also returns none it is recorded as `not-run`, never as passed. A quality review with no result is recorded the same way.
- `review-due` counts a periodic review as done only when its security result is `pass` or `blocked`, in the run state and in the history rows, so a partial or missing security review keeps the next one due.
- The delivery workflow notes a periodic start over its cap for the planner and names the areas a partial review left.
- `test/editor_normal.rb` gets its two waits back, and the backlog entry leaves.

Out of scope: the README's account of when the merger runs the metric line (queued in `run-budgets-tidy`), any change to the diff reviews, and retrying a partial review, which the next due review covers.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None: the change touches the delivery workflow, its agents, its scripts, and one test, and no editor behavior, so it sets `skip_specs: true`.

## Impact

- `.claude/workflows/periodic-review.js`, `.claude/workflows/deliver-change.js` (the periodic call site), `.claude/agents/security-reviewer.md` and `quality-reviewer.md` (their Periodic mode).
- `tools/run_state.sh` (`review`, `review-due`), `tools/tools_test.sh`.
- `test/editor_normal.rb`, `docs/backlog.md`, `CLAUDE.md`, `README.md`.

## Assumptions

- The periodic cap is one fixed figure, not scaled by an estimate: a periodic review reviews the whole tree whatever the size of the change that made it due, so it takes the largest figure the reviewers' `maxTurns` allows.
- A partial result outranks `blocked` in the recorded word, so a partial review never resets the review-due count; its blocking findings still reach the planner through the notes and the summary's `blocking=` count.
- A `not-run` record is written at the recording checkout's `HEAD`, since a review that returned nothing names no reviewed commit.
