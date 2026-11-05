# Tasks

## 1. Attribution off in the project settings

- [x] 1.1 `.claude/settings.json`: `attribution` with `commit` the trailer, `pr` empty, and `sessionUrl` false. Tested by the gate of 1.2 on this tree (`make gates`).
- [x] 1.2 `tools/gates.sh`: `gate_attribution` in the `static` group and the header. Tested by the `tools/tools_test.sh` cases "gates: attribution passes the trailer, no pull request text, and no session link", "gates: attribution refuses a session link", "gates: attribution refuses another commit trailer", "gates: attribution refuses pull request text", and "gates: attribution refuses a missing settings file".

## 2. The archive preview

- [x] 2.1 `tools/spec_validate.sh` (new) and the `spec-validate` target of the `Makefile`. Tested by "spec_validate: passes a change whose archive leaves valid specs", "spec_validate: refuses a change whose archive leaves an invalid spec", "spec_validate: archives a change without specs with --skip-specs", "spec_validate: leaves the real tree as it was", and "spec_validate: passes when every change as archived is valid".

## 3. The contributor

- [x] 3.1 `.claude/agents/contributor.md`: `make spec-validate` in implement steps 2 and 6, in fix, and in package step 1 in place of its `openspec validate --all --strict`; package step 5 a check that edits only a line the contributor did not write, and reports it. Tested by `make docs-lint` (the agent file's budget) and "guard: contributor generates and checks" with `make spec-validate`.

## 4. Docs and bookkeeping

- [x] 4.1 `CLAUDE.md` (the trailer rule and the `spec-validate` command), `README.md` (`make spec-validate`), and `docs/codebase-map.md` area 1 (`tools/spec_validate.sh`, the `attribution` gate, `.claude/settings.json`).
- [x] 4.2 `docs/backlog.md`: the five entries of `build/plan/backlog.md`.
- [ ] 4.3 Run `make tools-test`, `make docs-lint`, `make gates`, and `make spec-validate`.
