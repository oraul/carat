fix(gates): settle no pass across a docs/goals.md commit

## Summary

A check, security, or quality pass no longer stays current across a later commit that edits `docs/goals.md`, the one records-only path whose rules the agents act on (the tiers, the budgets, the critical-change routing). Before, any records-only commit kept a pass current, so a goals edit made after a review merged unreviewed: the security Low "A security review stays current after later instruction-file commits". This is the first part of the queue item, split at its start as its queue line asks: the `tools/gates.sh:112` list alone.

---

## Changes

- Add `INSTRUCTION_RECORDS_RE` (`docs/goals.md`) to `tools/gates.sh`, and make `settled_at` refuse a records-only diff that touches it, so the security, stages, passed, and records gates report a pass before such a commit as stale while backlog, findings, metrics, queue, and OpenSpec commits still keep it current.
- Change `tools/run_state.sh` to follow the same line through one shared filter, `outside_records`: `settled` no longer settles a round that changed `docs/goals.md`, `reviewed-edits` names it when it changed since the security review, and `moved` counts it as a file of the change, so no review is carried across a moved main past a branch commit to it.
- Add tools-test cases for the stale security and stages gates after a goals commit, the current gate after backlog and findings commits, `settled` refusing a goals round, `reviewed-edits` naming it, `moved` rerunning the reviews, and the two scripts' lines staying equal.
- Document in `README.md` and area 1 of `docs/codebase-map.md` that a pass stands after a records-only diff unless it touches `docs/goals.md`.
- Record the findings this change leaves open in `docs/findings/review-trust-lows.md`.
- Apply the planned backlog queue, which queues the remaining parts as `review-trust-lows-b` and `review-trust-lows-c`, and the lane's metrics row, trimming repeated queue wording to keep the two lane queues within their shared budget.
- Archive the OpenSpec change with its brief, proposal, design, and tasks.

---

## Testing

- Run the security review of the committed diff, passed with no High, Medium, or Low finding at the last reviewed commit
- Run the quality review, passed with no blocking finding and two advisories recorded in the findings file
- Run the checker's stages docs-lint, dev-build, test-build, diagnose, bench-budget, tools-test, test-run, gates, and metrics, all pass
- Run the benchmark review, passed
- Run make gates and make docs-lint on the packaged branch, both pass
- Run make spec-validate after the archive, 54 passed and 0 failed

---

## Notes

The change makes no `tools/rules.sh` edit: `RECORDS_RE` keeps `docs/goals.md`, so CI's and the checker's scopes still treat it as documentation and only the settle of a pass excludes it. `INSTRUCTION_RECORDS_RE` therefore lives in both scripts, held equal by a test, until a separate rules change moves it beside `RECORDS_RE`. `plan-apply` still copies a planned `goals.md` in the package step, which now makes the security pass stale and is named by `reviewed-edits`; both follow-ups are recorded in the findings file. The open-pr and sprint continuation Lows of the queue item follow as `review-trust-lows-b` and `review-trust-lows-c`.
