# Tasks

## 1. The settled probe

- [x] 1.1 `tools/run_state.sh settled CHANGE COMMIT`: exit 0 with `settled: only records changed from COMMIT to HEAD: FILES` on a clean tree whose diff since an ancestor COMMIT matches `RECORDS_RE` only, `docs/sprints.tsv` excluded; exit 1 naming the files, a dirty tree, or a COMMIT that is no ancestor; proved by "run_state: settled passes a records-only diff", "run_state: settled refuses a code change", "run_state: settled refuses a docs change outside the records", "run_state: settled refuses the sprints file", "run_state: settled refuses a dirty tree", and "run_state: settled refuses a commit that is no ancestor"
- [x] 1.2 `tools/agent_guard.sh` read profile allows `settled CHANGE COMMIT` only; proved by "guard: checker runs settled in an advisory-only round", "guard: checker refuses settled at a symbolic commit", "guard: the contributor may not run settled", and "guard: checker refuses settled without a commit"

## 2. The workflow

- [x] 2.1 `settleFrom`, `settled`, `settleRound`, and the settle line of `checkLines` and `checkRunTask` in `.claude/workflows/deliver-change.js`, wired into `rounds`; proved by "workflow: only the advisory round's fix asks the next check to settle", "workflow: an advisory-only round settles from the commit of the check, security, and bench passes", "workflow: a round offering a security finding keeps the security review", "workflow: a settled line naming the head skips the check", "workflow: a line naming code changed runs the check", "workflow: a settled round skips the check, security, and bench and records the skip", "workflow: a settled round's quality review reads only the commits since its pass", "workflow: the check start runs settled first only in an advisory-only round", and "workflow: a blocking round never settles"
- [x] 2.2 `settledTesting` in the package detail; proved by "workflow: the package step names the settled commit for Testing"
- [x] 2.3 `.claude/agents/checker.md` Mode run names the settle line
- [x] 2.4 `settledTesting` names the settled commit only while the settled round is at the head, so a full round after it (an in-place code fix, a blocking finding, a CI fix) is told nothing stale; proved by "workflow: a full round after a settled one names no settled commit for Testing"
- [x] 2.5 `settleAfter`: the in-place fix asks the next check to settle only when it moved the head, so a fix that made no commit leaves no settle for a later round; proved by "workflow: only the advisory round's fix asks the next check to settle"
- [x] 2.6 `settleBase`, `checkOutcome`, and `roundSettle` carry the verdict handling and the alone-path decision of `rounds`, tested as behavior instead of source text; proved by "workflow: the check verdict settles, reruns, or stands, never settling after a moved main" and "workflow: a blocking round never settles"
- [x] 2.7 The run's metric line leads the settle line and leaves the check line in an advisory-only round, so a settled round records its figures once; proved by "workflow: the check start runs settled first only in an advisory-only round" and "guard: the checker's run start may run the settle line with the run's figures"

## 3. Docs and checks

- [x] 3.1 README.md (pipeline step 5), `docs/codebase-map.md` (`tools/run_state.sh`), `docs/goals.md` (the in-place re-review rule)
- [x] 3.2 `make tools-test`, `make docs-lint`, `make gates`, and `make spec-validate` pass
