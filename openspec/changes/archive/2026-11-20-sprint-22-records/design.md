# Design

## Context

The sprint-22 plan in `build/plan/` is applied by the two `run_state.sh` commands; no code changes.

## Decisions

- Apply `history` then `groom` unedited, so the records equal the planner's output.
- One hand edit so `make docs-lint` passes, the only one: a backlog line names the removed findings file of `grep-long-files` in backticks, now plain words (the known groom gap of references to the findings files it removes).
- No delta specs: `skip_specs: true`, archived with `--skip-specs`.

## Risks

None: documents only.
