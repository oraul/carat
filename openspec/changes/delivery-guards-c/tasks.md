## 1. Implementation

- [x] 1.1 Keep the last implement or fix start's self-check and compare it with the next finished check, noting `self-check-mismatch` and escalating on a contradicted match (`.claude/workflows/deliver-change.js` selfCheck, compareSelfCheck, contributor, rounds; proved by the tools-test cases of 2.1)

## 2. Tests and docs

- [x] 2.1 Tools-test cases: a match the failed check contradicts is noted `self-check-mismatch` and moves `calibrated.contributor` to `session/session`; a mismatch, a passed check, or another mode's start writes no note; `contributor()` records the implement start's self-check (`tools/tools_test.sh`)
- [x] 2.2 Name the contradicted self-check as an escalation trigger in `docs/goals.md` and the README's pipeline paragraph (checked by `make docs-lint`)

## 3. Review fixes

- [x] 3.1 Build the self-check-mismatch text once in `compareSelfCheck` and use it for the report note and the queued line (`.claude/workflows/deliver-change.js`; the first self-check case of `tools/tools_test.sh`)
- [x] 3.2 Move the finished-check branch of `rounds()` into `finishCheck(v)` and the clearing of `selfCheck` into `settleRound`, replacing the layout-bound source regexes with cases that run both and an order-only check of the call (`tools/tools_test.sh`)
- [x] 3.3 Count only the refusals of the contributor's own tree (tracked files differing from HEAD, untracked files spin compiles) as a contradicted self-check, an environmental one such as `CHECK_JOBS` noting nothing (`CONTRIBUTOR_REFUSAL`; the refusal case of `tools/tools_test.sh`; `docs/goals.md`)
- [x] 3.4 Write the kept self-check as `(result && result.self_check) || ''` (`.claude/workflows/deliver-change.js` contributor)
