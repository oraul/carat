# Design

## Context

`contributor(mode, detail)` reads a start's `self_check` only to escalate on `mismatch`. The check loop in `rounds()` reads the checker's verdict (`checkVerdict`, `checkOutcome`) after the contributor's last start, in another function, so nothing compares the two. `escalate(why)` moves later contributor starts to the session's model once a run and queues an `escalation` note.

## Decisions

- A module variable `selfCheck` holds `{ mode, said }` from the last implement or fix start (`said` the result's `self_check`, '' when absent); `contributor()` sets it after each start of those modes and clears it after a start of any other mode.
- `compareSelfCheck(v)` takes the verdict of a check that finished at the head, clears `selfCheck`, and, only when it said `match` and `v.kind` is `failed` (a refusal only when its message is one of the contributor's own tree, `CONTRIBUTOR_REFUSAL`), builds one text, `contributor <mode> self-check said match, the check failed at stage <stage>` (the stage through `safeText`, so the line stays closable), adds it as a report note, queues `sh tools/run_state.sh note <change> self-check-mismatch "<text>"`, and calls `escalate('a self-check the check contradicted')`.
- `finishCheck(v)` holds the branch of `rounds()` for a check that finished at the head: the first-pass verdict, the report note, and `compareSelfCheck`, returning whether it passed, so a tools-test case runs it over a stubbed verdict; `settleRound` clears `selfCheck` (a settled round stands on a pass); a rerun keeps it for the check that finishes.
- No delta specs: `skip_specs: true`, archived with `--skip-specs`.

## Risks

None beyond one more note: the escalation it triggers is the existing one, once a run, and a critical run already uses the session's model.
