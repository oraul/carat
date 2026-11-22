# Design

## Context

The sprint-26 plan in `build/plan/` is applied by the two `run_state.sh` commands; no code changes.

## Decisions

- Apply `history` then `groom` unedited, so the records equal the planner's output.
- No delta specs: `skip_specs: true`, archived with `--skip-specs`.

## Risks

None: documents only.
