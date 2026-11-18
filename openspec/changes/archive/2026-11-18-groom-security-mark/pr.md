fix(tools): keep groom's security entries in any wording

## Summary

Makes the backlog grooming keep a security entry in any wording until a merged change lists it or a sprint commit fixes it, and keeps a merged entry's body under its kept heading whatever its text says. The sprint-18 periodic security review found that an entry marked only "Low finding of the periodic security review" could leave as closed, gone, a duplicate, or a merge into a plain entry (Medium, confidence 9), and that a merged body line starting `@@kept` redirected the rest of the body and could drop it (Low, confidence 3).

---

## Changes

- Change `SECURITY_MARK` in `tools/run_state.sh` to accept the word security and a severity in either order and across the entry's lines, or a severity and confidence pair, critical included, judged by one new `security_entry` function
- Refactor groom's four repeated security checks into one guard before the kinds' proofs that refuses closed, gone, and duplicate for a security entry and a merge into a non-security entry
- Fix the merged-body channel so each kept heading and each body line carries its own prefix, and a body line such as `@@kept X` stays in place under its kept heading
- Add tools-test cases refusing closed, gone, duplicate, and a non-security merge for an entry marked only "Low finding of the periodic security review", entries worded "rated Medium" and "rated Critical", an entry with security and its severity on different lines, and a Critical severity and confidence pair
- Add tools-test cases keeping a merged body line starting `@@kept` under its heading and sending no line to a heading a body line names
- Document the security entry's wording in README.md pipeline step 11 and the `groom` description in `docs/codebase-map.md`
- Archive the OpenSpec change with its proposal, design, and tasks, no spec changed

---

## Testing

- Run the security review of the committed diff, pass with no High, Medium, or Low finding
- Run the quality review, pass with no blocking or advisory finding after the review-fix round that added the two missing test fixtures
- Run the checker's stages (diagnose, docs-lint, dev-build, test-build, test-run, gates, tools-test, bench-budget, metrics), all pass
- Run the benchmark review, pass with no blocking finding
- Run make spec-validate after the archive, 54 passed and 0 failed

---

## Notes

This is the sprint-18 security-first change, delivered alone before sprint-18-records, which applies the waiting plan. `tools/rules.sh` is not edited, and backlog-pick's own wider security ranking is unchanged. Judging security over the whole entry errs toward keeping an entry, which still leaves by listed or fixed.
