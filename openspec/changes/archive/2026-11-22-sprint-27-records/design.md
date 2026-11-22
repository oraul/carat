# Design

## Context

The sprint-27 plan in `build/plan/` is applied by the two `run_state.sh` commands; no code changes.

## Decisions

- Apply `history` then `groom` as they stand, so the records equal the planner's output, except that the word "estimated" is added before the size of seven Pool items of `docs/queue-feature.md`, which `docs-lint` requires.
- No delta specs: `skip_specs: true`, archived with `--skip-specs`.

## Risks

None: documents only.
