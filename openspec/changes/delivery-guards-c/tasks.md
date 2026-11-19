## 1. Implementation

- [ ] 1.1 Keep the last implement or fix start's self-check and compare it with the next finished check, noting `self-check-mismatch` and escalating on a contradicted match (`.claude/workflows/deliver-change.js` selfCheck, compareSelfCheck, contributor, rounds; proved by the tools-test cases of 2.1)

## 2. Tests and docs

- [ ] 2.1 Tools-test cases: a match the failed check contradicts is noted `self-check-mismatch` and moves `calibrated.contributor` to `session/session`; a mismatch, a passed check, or another mode's start writes no note; `contributor()` records the implement start's self-check (`tools/tools_test.sh`)
- [ ] 2.2 Name the contradicted self-check as an escalation trigger in `docs/goals.md` and the README's pipeline paragraph (checked by `make docs-lint`)
