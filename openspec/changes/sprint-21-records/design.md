# Design

## Context

The sprint-21 plan in `build/plan/` is applied by the two `run_state.sh` commands; no code changes.

## Decisions

- Apply `history` then `groom` unedited, so the records equal the planner's output.
- Two hand edits so `make docs-lint` passes, the only ones: the lane queues exceed their shared byte budget by 174 bytes as the planner wrote them, so the backlog queue drops its "Delivered" and "Merge gate" Decisions bullets (both recorded elsewhere, in `docs/sprints.tsv` and the run states) and loses two clauses; and one backlog line names the removed findings file of `finder-grep-preview` in backticks, now plain words (the known groom gap of references to the findings files it removes).
- No delta specs: `skip_specs: true`, archived with `--skip-specs`.

## Risks

None: documents only.
