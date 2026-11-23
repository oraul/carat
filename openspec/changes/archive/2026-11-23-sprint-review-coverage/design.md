# Design

## Context

The planner's sprint start reviews the combined diff's quality and plans the next sprint under one cap of 80 calls. Its result lists the files it did not cover in `not_reviewed`; the workflow recorded `periodic-quality partial` with their count and nothing reviewed them. The security review already gets one more start over the files it left (`reviewContinued`, `mergeSecurity`).

## Goals / Non-Goals

**Goals:**
- Every file of the combined diff, tests and specs included, is reviewed, by a continued start when the first cannot cover them.
- A review that still leaves files is recorded partial, never passed, and the report names the coverage.

**Non-Goals:**
- Raising the planner's cap, or planning from the continued findings (they arrive after the queue is written).

## Decisions

- The continuation is a quality-reviewer start (its Sprint mode) rather than a second planner start, so the planning and grooming are not repeated; it reuses `reviewTaskOf`, the text the security continuation uses, with the files the planner left.
- `reviewContinued` is not reused: it starts the first review itself, while the quality review's first start is the planner's. `mergeQuality` mirrors `mergeSecurity`: counts added, notes joined, `not_reviewed` what the second start still names, matched with `stillLeft` so another spelling of a file never drops it; a continued start without a result returns the planner's review unchanged, so every file stays left and the record is partial.
- The continued start's notes join the planner's before `reviewNotes`, so they reach the run state through the same single-quoted record start and no finding text reaches a shell.
- The quality line says `coverage: N of M file(s) the first start left reviewed in a continued start`, and the files still left with `partial`; a review with no file left says every file was reviewed.
- The continued start's cap is the review cap (53), within the quality reviewer's `maxTurns`; an overrun is noted as the other sprint starts' are.
