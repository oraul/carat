# Design

## Context

The sprint-19 plan in `build/plan/` is applied by the two `run_state.sh` commands; no code changes.

## Decisions

- Fix two stale paths in the feature queue by hand (see Hand edit).
- Apply `history` then `groom` unedited, so the records equal the planner's output.
- No delta specs: `skip_specs: true`, archived with `--skip-specs`.

## Risks

None: documents only.

## Hand edit

Two backticked paths of the planner's `docs/queue-feature.md` named moved files (`arrange_view.rb` and `fold_handler.rb`); they now name the real paths, so `make docs-lint` passes. Nothing else of `groom`'s output is edited.
