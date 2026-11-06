# Design

## Context

`.claude/workflows/periodic-review.js` starts the security and quality reviewers in their Periodic mode with one task line and no cap, retries a security start whose `ran` is false once, and records `periodic-security` and `periodic-quality` through one record start, only from a result with a commit as its head. With no result nothing is written. `tools/run_state.sh review` takes `pass` or `blocked`; `review-due` counts a change with any `review.periodic-security` key, and a history row whose review column is not `-`, as reviewed. The reviewers' `maxTurns` is 58, the large diff-review cap of 53 plus the return margin of 5 (`tools/tools_test.sh`, the caps cases).

## Goals / Non-Goals

Goals: every periodic start states its cap and leaves the margin to return; a capped review returns what it covered and names what it did not; a security review never ends unrecorded and is never recorded as passed without a result.

Non-goals: scaling the periodic cap by an estimate, retrying a partial review, changing the diff reviews or their gates.

## Decisions

- One fixed cap, `PERIODIC_CAP = 53`, in `periodic-review.js`, stated in each reviewer start and the retry with the same sentence shape as the delivery workflow's `capLine`, and `RECORD_CAP = 3` for the record start. A workflow script cannot read the agent files, so `tools/tools_test.sh` reads the constant and checks it plus the margin against both reviewers' `maxTurns`, and checks that every `agent(` call of the script states a cap.
- `not_reviewed` is a required schema field of fixed-shape values: the security reviewer's areas as an enum (`config`, `files`, `plugins`, `terminal`, `processes`, `shell-tools`, `ci`, `agents`) and the quality reviewer's map areas as integers. The values go into a shell command the record start runs, so a reviewer cannot place free text there; the schema, not a filter, keeps the line safe.
- The recorded word is `not-run` with no result, `partial` when `not_reviewed` is not empty, `blocked` when a finding blocks, else `pass`. The summary keeps its counts and adds `not_reviewed=a,b`. `partial` outranks `blocked` so that a partial review keeps the next one due; the blocking count stays in the summary and the findings in the notes.
- `run_state.sh review` admits `partial` and `not-run` only for `periodic-*` kinds, so the merge gate's reading of the diff reviews is unchanged; neither writes a phase. `review-due` counts a periodic review as done only when the first word of `review.periodic-security`, or the history row's `security=` value, is `pass` or `blocked`.
- A security result counts as returned only when `ran` is true and its head is a commit; otherwise the one retry runs, and a retry without one records `not-run` at `HEAD`. The periodic result's `ran` stays false then, so the delivery workflow still stops with `the periodic security review did not run; run /review`.
- The periodic result returns each start's calls and the cap; the delivery workflow notes each one over the cap with its `overCap`, and names a partial review's areas in its periodic note.

## Risks / Trade-offs

- A reviewer that ignores the stated cap still reaches `maxTurns` with no result; the retry and the `not-run` record bound that case, and the history row shows it.
- A `partial` security review keeps the review due, so a run that stops partway costs a second periodic review at the next merge; that is the price of never counting unreviewed areas as reviewed.
- The tools_test cases read `periodic-review.js` by pattern, as the existing caps cases read `deliver-change.js`; a rewrite of its shape must keep the patterns.
