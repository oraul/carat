# Design

## Context

The sprint-28 plan in `build/plan/` is applied by the two `run_state.sh` commands; no code changes.

## Decisions

- Apply `history` then `groom` as they stand, so the records equal the planner's output.
- Hand-fix only what `make docs-lint` refuses in the queues, as the user answered on 2026-11-22 and the sprint-27 records change did: the backlog sprint kept at its 3 items, the other two moved unchanged to the Pool for Sprint 30.
- No delta specs: `skip_specs: true`, archived with `--skip-specs`.

## Risks

None: documents only.
