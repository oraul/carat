# Design

## Context

See proposal.md, Why. `check_stages` (tools/run_state.sh) loops over the stage list: a stage passed at the backed head is skipped, one passed before a test-only commit carried, one out of the path scope recorded scoped, a compile stage on the same code key and outputs recorded compiled; any other runs through `run_stage`, which writes the `running` record, runs the stage in the background, waits for it, appends its log's last line, and writes the final record. The runner keeps one `child` and one `running_stage` for its signal trap, and `write_key` rewrites the run state through `$file.tmp.$$`, where `$$` is the runner's pid even in a background subshell, so two writers at once would share one temporary name.

## Goals / Non-Goals

Goals: run the ready stages at once under a cap; keep every log, record, exit status, and verdict line; keep the skip rules; stop and record every running stage on a failure or a signal.

Non-Goals: a lock around the run state, CI, `make check`.

## Decisions

- One writer. Only the runner writes the run state and `build/pipeline/compiled`. A stage runs as a background job (a subshell) that starts the stage command with its log, waits for it, and writes its exit status to `JOBS/NAME.status` through a temporary file and `mv`, JOBS being a directory beside the check clone's repository, removed with it. The runner polls the running stages' status files every `pause` (0.2 s), its sleep started in the background and waited for, so a trapped signal ends the wait at once; then it reaps the job and writes the final record. Alternative: a lock (`mkdir`) around `write_key`; rejected, since a runner killed while holding it would leave a lock the next check must judge stale, and no other writer needs it.
- The job forwards a terminate signal to its stage command and waits for it again, so stopping a job stops its stage and leaves its real exit status. The runner, detached by `setsid`, still ends its whole process group on a signal, as before.
- Order. `STAGE_AFTER` lists `STAGE:BEFORE` pairs; a pair counts only when both are in the list, and BEFORE counts as passed once it is neither queued nor running, since a stage that does not pass ends the check. A skipped, carried, scoped, or compiled stage is never queued, so it counts as passed at once. `STAGE_ALONE` stages start only with nothing running and hold every other start while they run. A free slot takes the first ready stage in list order, so list order stays the tie-break.
- `CHECK_JOBS` (default 3) caps the jobs; a value that is not a positive number is refused before any stage starts. The figure comes from the measured seconds (proposal).
- A stage's start is recorded in `JOBS/NAME.start` ("PID SECONDS COMMIT"), which the signal trap reads for every running stage. `run_stage`, used by `tools/run_state.sh stage`, keeps its own synchronous path, sharing the end of a stage (`stage_end`: the log's last line, the record, the message, the status) with the scheduler.
- Failure. On the first stage that does not pass, the runner stops the running stages (`stages_stop`), each recorded `killed` with `KILLED: the check stopped after stage NAME failed`, prints the failing log's last 20 lines prefixed by `| `, and then the verdict line, which stays the last line `check_verdict` reads.
- `check_lost` records every stage left `running`, the verdict naming the first.

## Risks / Trade-offs

- Six stages at once on 4 CPUs when two lanes check together: each stage runs slower than alone, so the wall time gained is less than the floor; `CHECK_JOBS=1` restores the old order.
- metrics' time figures: it runs alone, but bench-budget and the compilers before it may have warmed or cooled caches differently from a sequential run; allocations and rounds, which decide, are deterministic.
- The poll adds up to 0.2 s per stage end.

## Migration Plan

None: the stage records keep their format, so a check that ran sequentially is read the same.

## Open Questions

None.
