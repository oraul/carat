fix(tools): take a stage's pass from the runner's own child

## Summary

Makes the check runner take each stage's result from the exit status of its own child process, and makes a failing stage's log excerpt show control bytes as visible text. A stage runs branch code and could write a sibling stage's job files to forge a pass, and an escape sequence in a log reached the terminal raw.

---

## Changes

- Change `tools/run_state.sh` so a stage's job subshell exits with the stage's status and the runner reads it with `wait`, and remove the jobs directory with its status and start files
- Keep each job's pid, start second, and commit in runner variables, and see an ended job from the process table instead of a file, in `stages_reap` and `stages_stop`
- Change the failing stage's log excerpt to print control bytes and C1 controls as visible characters, so no escape sequence reaches the terminal
- Add `tools/tools_test.sh` cases for a stage that writes a sibling stage's job files without changing its record, and for a failing stage whose log holds an ESC sequence
- Record the unfiltered changed-path list of the escape scan as a finding

---

## Testing

- Run the security review on the committed diff, pass with no High, Medium, or Low finding
- Run the quality review, one finding added and recorded in the findings file, none blocking
- Run every stage of `make check` at the implementation head, all pass, including `make tools-test` with the new cases
- Run the benchmark against `main`, pass with nothing blocking
- Run `make spec-validate` after the archive, all pass

---

## Notes

None
