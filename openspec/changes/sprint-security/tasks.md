# Tasks

## 1. Run state gate

- [ ] 1.1 Require the even sprint's sweep record (pass, blocked, or partial) in `sprint_reviewed` (`tools/run_state.sh`); proved by "groom holds a plan whose sprint sweep failed to start", "review-due stays due while the sprint sweep failed to start", "groom holds a plan whose sprint sweep did not run", and "review-due is not due while the sprint plan waits, its sweep partial" in `tools/tools_test.sh`, with "review-due stays due while the sprint's security review is partial" and "groom holds a plan whose sprint security review did not run"

## 2. Sprint workflow

- [ ] 2.1 Record each security finding from the reviewer's result in a Notes step before the skeptic with `shellWord` and `securityNotes` (`.claude/workflows/sprint-planning.js`), the skeptic recording only its disputes; proved by "sprint: each security finding is recorded verbatim from the reviewer's result, no skeptic" and "sprint: the notes are recorded before the skeptic starts"
- [ ] 2.2 Record a sweep that failed to start as not-run and start the planner only after a complete security review, its notes, the skeptic, and the sweep; proved by "sprint: the planner starts only after a complete security review, its notes, the skeptic, and the sweep" and "sprint: a sweep that failed to start is recorded as not run"
- [ ] 2.3 Name a partial review in the report's Security line with `securityLine`; proved by "sprint: the report names a partial security review"

## 3. Docs

- [ ] 3.1 Update the security and quality reviewer agents' sprint and skeptic modes, README.md's sprint planning paragraph, and docs/codebase-map.md area 1 (docs only, `make docs-lint`)

## 4. Checks

- [ ] 4.1 `make tools-test`, `make gates`, `make spec-validate`, and `make docs-lint` pass
