chore(delivery): guard findings and pull request text

## Summary

Adds two mechanical guards to the delivery pipeline: an append-only check on findings entries and a review of the pull request text against the committed diff. The first three deliveries of the mid-tier contributor trial let a dropped findings entry and a pull request body claiming work not in its diff reach main past the reviewers, because only the contributor's word vouched for them. The contributor's result contract and self-check mismatch note are split off as delivery-guards-b.

---

## Changes

- Add a findings gate to tools/gates.sh, in static, pre-push, and merge, that fails when a findings heading present at the fork point of the base and HEAD, or added by a non-merge commit of the branch, is missing at HEAD, while a sprint records change passes
- Add a pull request text review to the workflow: after the package push, a capped session-model quality reviewer compares the Summary and Changes of pr.md with the diff and the archived proposal's Out of scope, and a block sends it back to the contributor's body mode for one rewrite
- Add a push kind for a pr.md rewrite, one per run, counted by the pushes gate and allowed by the agent guard
- Add tools-test cases for the findings gate, the push kind, the text review decision, and a pr.md claiming out-of-scope work
- Restore the dropped LineNrFifth entry in the cursor-and-messages findings and record that the squash body of 223 claims styling not in its diff
- Document the new gate and text review in README.md, CLAUDE.md, and the gates usage text

---

## Testing

- Run the checker's fast stages (docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, tools-test, gates, metrics) on the implemented head, all pass
- Run make gates and make docs-lint on the packaged branch, both pass
- Run make spec-validate after archiving, 54 of 54 pass
- Security review of the committed diff, no findings, nothing blocking
- Quality review of the committed diff, nothing blocking, four advisory findings recorded
- Benchmark review, nothing blocking

---

## Notes

The advisory findings, including that the text review does not run on a resume past the package phase, are recorded in docs/findings/delivery-guards.md. tools/rules.sh is not edited. The result contract and self-check mismatch note are queued as delivery-guards-b.
