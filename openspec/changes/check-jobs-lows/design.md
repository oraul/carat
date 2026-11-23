# Design

## Context

The runner started each stage in a background subshell that wrote its status into `jobs/NAME.status` next to the clone, and read `jobs/NAME.start` for its pid, start, and commit. A stage runs branch code in the clone and can reach the sibling directory.

## Goals / Non-Goals

**Goals:**
- A stage's pass comes only from the exit status of the runner's own child, which no stage can write.
- The excerpt of a failing stage shows no control byte.

**Non-Goals:**
- Sandboxing stages from each other beyond this; the escape scan stays as it is.

## Decisions

- The job subshell is the runner's child, so `wait PID` returns its exit status, and the subshell ends with the stage's status. No file carries a result. The pid, start, and commit are runner variables (`job_table`), unreachable from a stage.
- A job ended is seen with `ps -o stat= -p PID` (empty or `Z`), because `kill -0` still succeeds on an unreaped child. `wait` is only called on an ended job, so the runner never blocks on a running stage.
- The excerpt goes through `visible_text`: tab and NUL become a space, every other control byte `?`, in the C locale so UTF-8 text is kept.
