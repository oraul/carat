# Tasks

## 1. Rules in the repository

- [x] 1.1 `CLAUDE.md`: the `## Main session` section before `## Stack`, paid for by tightening existing prose, under the 30,720-byte budget. Test: `make docs-lint`.
- [x] 1.2 `docs/goals.md`: the `## Main session` section with each rule's reason and the resume defects it does not claim to fix. Test: `make docs-lint`.

## 2. Checks

- [x] 2.1 Each rule's place named in the proposal; README.md, `docs/architecture.md`, and the code map stay unchanged with their reasons. Test: `make gates`, `make docs-lint`, `make spec-validate`.

## Quality review

- [x] 3.1 `docs/goals.md` first bullet claimed a stopped run leaves a worktree and run state half written, which no document in the repository states; reworded to what a stop costs. Fixed.
- [x] 3.2 `CLAUDE.md` is left with 16 bytes under its budget and the rules have no enforcing tooling; both appended to `docs/findings/session-rules.md`. Recorded.
