fix(workflow): note a self-check the next check contradicts

## Summary

The delivery workflow now compares the contributor's self-check with the next check that finishes at the head, notes `self-check-mismatch` when a self-check of match meets a failed stage, and moves the run's later contributor starts to the session's model. Until now a "gates clean" claim that met a failed gates stage left no trace in the run state, so the escalation rule for a self-check mismatch never fired for it.

---

## Changes

- Keep the self-check of the last implement or fix start in `.claude/workflows/deliver-change.js` until the next check finished at the head reads it, any other contributor mode or a settled round clearing it
- Add the comparison: a failed stage after a self-check of match writes a report note and a queued closable `self-check-mismatch` note from one text, then escalates later contributor starts to the session's model, once a run and never in a critical run
- Count a refusal of the contributor's own tree (tracked files differing from HEAD, untracked files spin compiles) as the failed stage `refused`, while an environmental refusal such as `CHECK_JOBS` notes nothing
- Move the finished-check branch of the round loop into `finishCheck` and the clearing of the kept self-check into `settleRound`
- Add tools-test cases for the noted mismatch and the escalation to `session/session`, no note for a self-check of mismatch, a passed check, or another mode's start, the recording of the implement start's self-check, and the refusal messages of `tools/run_state.sh check`
- Document the contradicted self-check as an escalation trigger in `docs/goals.md` and the README's pipeline paragraph
- Record the plan's backlog queue and the metrics history row of the backlog lane

---

## Testing

- Run the security review of the committed diff, pass with no High, Medium, or Low finding
- Run the quality review, pass with no blocking or advisory finding
- Run the checker's stages (diagnose, dev-build, test-build, test-run, gates, docs-lint, tools-test, bench-budget, metrics), all pass
- Run the benchmark comparison, pass
- Run make spec-validate, 54 passed and 0 failed
- Run make gates and make docs-lint, both pass

---

## Notes

This is the rest of delivery-guards-b by the split rule, run under the user-approved exception of Sprint 21 in the backlog lane. The kept self-check lives in the workflow's memory, so a workflow restart carries none across, as the head guard's refusal count does; `tools/rules.sh` is not edited.
