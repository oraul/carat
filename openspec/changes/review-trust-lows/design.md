## Context

`settled_at` in `tools/gates.sh` decides whether a pass recorded at a commit still holds at HEAD: every path changed since must match `RECORDS_RE` (`tools/rules.sh:69`), `docs/sprints.tsv` only by groom's one row. The security (`gate_security`), stages, passed, and records gates call it, and main's copy runs at the merge. `tools/run_state.sh` mirrors it in `settled_round` (review-lite, which the workflow uses to let a records-only fix round stand on earlier passes) and `reviewed_edits` (the package step's edit guard). `RECORDS_RE` also feeds `documentation` (CI's and the checker's scope) and `TEST_ONLY`.

## Goals / Non-Goals

**Goals:**
- A pass before a commit to an instruction record is stale at every gate and in review-lite.
- Backlog, findings, metrics, queue, OpenSpec, and groom sprint-row commits keep a pass current.

**Non-Goals:**
- Editing `RECORDS_RE` (the merge gate's rules, a change of its own), or the stage scopes, where `docs/goals.md` stays documentation.

## Decisions

- A second pattern, `INSTRUCTION_RECORDS_RE='docs/goals\.md$'`, subtracted from the settle, rather than removing `docs/goals.md` from `RECORDS_RE`: that list is `tools/rules.sh`, which the brief forbids editing here, and it also decides the stage scopes, which should still skip compiling for a goals edit.
- The line is kept in both `tools/gates.sh` and `tools/run_state.sh` (each sources only `tools/rules.sh`), and a tools-test case compares the two, as the guard's `RISKY_CONFIG` copy is compared today.
- `settled_round` adds the instruction records to the names it reports ("changed since COMMIT outside the records a pass settles across"), keeping the message's prefix the workflow and the tests read.
- `reviewed_edits` lists an instruction record beside the files outside `RECORDS_RE`, so a package step that edited `docs/goals.md` after the security review restores it rather than reaching a push gate that refuses.

## Risks / Trade-offs

- A planner-written `goals.md` applied by `plan-apply` in the package step now trips `reviewed-edits`; it has not happened in the history (every commit to `docs/goals.md` came through a contributor's implement step), and it is recorded as a finding with a fix outline.
- Main's merge gate applies the rule only after this change merges; this change itself touches no instruction record after its review.
