# Tasks

## 1. The settled probe

- [ ] 1.1 `tools/run_state.sh settled CHANGE COMMIT`: exit 0 with `settled: only records changed from COMMIT to HEAD: FILES` on a clean tree whose diff since an ancestor COMMIT matches `RECORDS_RE` only, `docs/sprints.tsv` excluded; exit 1 naming the files, a dirty tree, or a COMMIT that is no ancestor; proved by "run_state: settled passes a records-only diff", "run_state: settled refuses a code change", "run_state: settled refuses a docs change outside the records", "run_state: settled refuses the sprints file", "run_state: settled refuses a dirty tree", and "run_state: settled refuses a commit that is no ancestor"
- [ ] 1.2 `tools/agent_guard.sh` read profile allows `settled CHANGE COMMIT` only; proved by "guard: checker runs settled" and "guard: checker refuses settled without a commit"

## 2. The workflow

- [ ] 2.1 `settleFrom`, `settled`, `settleRound`, and the settle line of `checkLines` and `checkRunTask` in `.claude/workflows/deliver-change.js`, wired into `rounds`; proved by "workflow: an advisory-only round settles from the commit of the check, security, and bench passes", "workflow: a round offering a security finding keeps the security review", "workflow: a settled line naming the head skips the check", "workflow: a line naming code changed runs the check", "workflow: a settled round skips the check, security, and bench and records the skip", "workflow: a settled round's quality review reads only the commits since its pass", "workflow: the check start runs settled first only in an advisory-only round", and "workflow: a blocking round never settles"
- [ ] 2.2 `settledTesting` in the package detail; proved by "workflow: the package step names the settled commit for Testing"
- [ ] 2.3 `.claude/agents/checker.md` Mode run names the settle line

## 3. Docs and checks

- [ ] 3.1 README.md (pipeline step 5, the run state paragraph), `docs/codebase-map.md` (`tools/run_state.sh`, `tools/agent_guard.sh`), `docs/goals.md` (the in-place re-review rule)
- [ ] 3.2 `make tools-test`, `make docs-lint`, `make gates`, and `make spec-validate` pass
