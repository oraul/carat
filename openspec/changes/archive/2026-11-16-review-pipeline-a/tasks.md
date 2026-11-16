# Tasks

## 1. Stale red

- [x] 1.1 Key `staleRed` in `.claude/workflows/deliver-change.js` by workflow file and check name, refusing an entry without a workflow file; update the MERGE schema's `checks` description and the merger's step 2; proved by "workflow: a red superseded by a green run of the same check is stale" and "workflow: another workflow's green run does not clear a red one" in `tools/tools_test.sh`

## 2. Periodic review

- [x] 2.1 Give `missedOf` in `.claude/workflows/periodic-review.js` the result's kind and pass it at every caller; proved by "periodic: missedOf keeps only its own kind's values"
- [x] 2.2 Reorder the not-run sentence of the security reviewer's periodic step 5 to the workflow's order (a wording fix, no test)

## 3. Continued security prompt

- [x] 3.1 Add `continuedSecurity`, make `reviewMore` a function, and use them in `securityReview`; proved by "workflow: the continued security prompt leaves the last file alone on its line"

## 4. Review scope

- [x] 4.1 Pin the sprint review's unfiltered combined diff; proved by "sprint: the sprint review covers the whole combined diff, the record keepers included"

## 5. Docs and checks

- [x] 5.1 Update the README's stale red sentence; run `make tools-test`, `make docs-lint`, `make gates`, and `make spec-validate`
