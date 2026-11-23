# Proposal

## Why

`tools/run_state.sh check` runs each stage as a job in the background. The job's subshell wrote the stage's exit status to `NAME.status` in a jobs directory beside the check clone, and the runner read that file as the stage's result. The directory is reachable from the clone, so a stage's branch code could write a sibling stage's `.status` (or `.start`) and make the runner record a pass it never observed. Separately, the failing stage's last log lines are printed to the terminal raw, so an escape sequence in a log reaches the terminal.

## What Changes

- The runner takes a stage's result from its own child: the job subshell exits with the stage's status and the runner reads it with `wait`. The jobs directory, `NAME.status`, and `NAME.start` are removed; each job's pid, start second, and commit live in a runner variable. An ended job is seen by the process table (gone or a zombie), never by a file.
- `stages_reap` and `stages_stop` use that, keeping every record and log line they wrote.
- The failing stage's log excerpt prints control bytes (ESC, CR, NUL, tab) and C1 controls (the UTF-8 pair C2 80 to C2 9F, a raw byte 80 to 9F) as `?`, so no escape sequence reaches the terminal.
- `tools/tools_test.sh`: a stage that writes a sibling stage's job files cannot change that stage's record, and a failing stage whose log holds an ESC sequence prints it without the ESC byte.

Out of scope: the changed-file path list of the escape scan prints unfiltered too (recorded in the findings file).

Assumptions: `ps -o stat=` is available where the check runs (the runner already uses `ps -o pgid=`).

## Capabilities

### New Capabilities

### Modified Capabilities

## Impact

- Code: `tools/run_state.sh`.
- Tests: `tools/tools_test.sh`.
- README.md: unchanged, no user-visible behavior or spec changed.
- CLAUDE.md: unchanged, it names `check` only as running the stages detached.
- docs/architecture.md: unchanged, no spec changed.
- docs/codebase-map.md: unchanged, no file added, moved, or removed.
- No edit of `tools/rules.sh`.
