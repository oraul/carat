# Tasks

## 1. Run state results

- [x] 1.1 `tools/run_state.sh` `review`: admit `partial` and `not-run` for the `periodic-*` kinds only, neither writing a phase; update the header; proven by new `tools/tools_test.sh` run_state cases.
- [x] 1.2 `tools/run_state.sh` `review-due`: count a periodic review as done only when its security result is `pass` or `blocked`, in the run state and the history rows; proven by new `tools/tools_test.sh` review-due cases.

## 2. Periodic review caps and results

- [x] 2.1 `.claude/workflows/periodic-review.js`: state `PERIODIC_CAP` in each reviewer start and the retry and `RECORD_CAP` in the record start; add the required `not_reviewed` fields; retry a security start without a result or a commit head; record `partial` and `not-run`; return each start's calls and the cap; proven by the `tools/tools_test.sh` caps cases for the periodic review.
- [x] 2.2 `.claude/workflows/deliver-change.js`: note a periodic start over its cap and a partial review's areas; covered by the same caps cases.
- [x] 2.3 `.claude/agents/security-reviewer.md` and `quality-reviewer.md`: the Periodic mode stops at the stated cap and returns `not_reviewed`; checked by `make docs-lint`.

## 3. Test restoration and docs

- [x] 3.1 `test/editor_normal.rb`: restore the two `h.wait` calls of the lone-prefix check, snapshot unchanged; proven by `make test-one T=test/editor_normal.rb`; remove its `docs/backlog.md` entry.
- [ ] 3.2 `CLAUDE.md` and `README.md`: say the periodic starts have a fixed cap and a partial or missing result is recorded; checked by `make gates` and `make docs-lint`.
