fix(tools): merge main with plain git and send every conflict to the contributor

## Summary

Removes the pinned git from the merge of a moved main and sends every conflict that merge meets to the contributor, so a delivery goes on after a moved main instead of stalling. Deliveries had stopped around that merge, and a conflict where both sides changed the same logic ended the main-moved start in a stop.

---

## Changes

- Change merge_main in tools/run_state.sh to run its merge, queue checkout, add, commit, and abort with plain git, keeping the pinned fetch and the check clone as they are
- Change the main-moved start in the delivery workflow so the contributor resolves every conflict, the same-logic case included, and commits the merge without stopping to ask
- Change the conflict message and the merge-main header in tools/run_state.sh to match, with no offer of a stop
- Document in docs/contributor-notes.md and README.md that a same-logic conflict is resolved by the contributor, never a stop
- Remove the two merge-main hook cases #328 added from tools/tools_test.sh
- Add a tools-test case that merge_main names pinned_git only on its fetch, and one that the main-moved start has no stop on a same-logic conflict
- Record the reopened finding, that merge_main runs git with global configuration and hooks again, in docs/findings/merge-git-unpin.md

---

## Testing

- Run the security review of the committed diff: no High or Medium finding, one Low at confidence 6 recorded as the reopened finding, not blocking
- Run the fast stages and tools-test on the head (docs-lint, dev-build, test-build, diagnose, bench-budget, test-run, gates, tools-test, metrics), all pass
- Run the benchmark review, pass with no blocking finding
- Run make spec-validate after the archive, 56 items pass

---

## Notes

The user asked to remove the pinned git only, so the hook hardening #328 put on merge_main is reverted and recorded as a finding; the agent guard and its configuration refusals stay as the controls. The record step's runner, ci-stages, and the rest of #328 are unchanged.
