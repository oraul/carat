fix(ci): validate every gh answer in the scope step

## Summary

The CI scope step now validates every GitHub API answer before using it and always writes a well-formed single-line reason, so a failed or malformed answer runs the checks instead of breaking the step. Main's CI failed when a server error body from an unchecked API call was stored as the pull request number and its line breaks corrupted the step output, breaking the script's promise that anything it cannot establish runs the checks.

---

## Changes

- Fix tools/ci_scope.sh to accept a pull request number or count only as digits and a commit or tree sha only as lowercase hex, treating any other answer, an error body included, as unknown so the checks run.
- Fix the scope reason to be written on one line with printf, so the step output always holds exactly one run line and one reason line whatever path or answer it names.
- Add tools-test cases with a stubbed gh that prints an error body and fails, on a push whose number query fails and on a push where every query fails, and a case whose commit adds a path holding a line break, each asserting run=true and a well-formed step output.
- Document the change in its archived OpenSpec proposal, design, and tasks, with no spec delta since no editor behavior changes.
- Record the planner's queue, the metrics row of the last merged change, and this change's non-blocking review findings in the backlog.

---

## Testing

- Run the security review of the committed diff, passed with no High or Medium finding and one Low finding at confidence 4 in existing code, recorded in the backlog.
- Run the checker's fast stages (docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, metrics, tools-test, gates), all pass.
- Run the quality review, passed with no blocking finding and advisories recorded in the backlog.
- Run the benchmark comparison against main's recorded figures, passed with no regression.
- Run make spec-validate after archiving, 51 items pass.

---

## Notes

The unquoted path loops in the scope script, which can expand a wildcard-named path against the checkout, are pre-existing and left for a follow-up recorded in the backlog, since this change is limited to the validation of the API answers and the output format.
