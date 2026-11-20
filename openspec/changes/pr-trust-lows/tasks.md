# Tasks

## 1. Pin OpenSpec

- [x] 1.1 `Makefile` (`OPENSPEC_PACKAGE`, `OPENSPEC`), `tools/spec_validate.sh`: run `@fission-ai/openspec@2.1.1`. Tested in `tools/tools_test.sh` by "spec_validate: runs the pinned OpenSpec when no command is given" and "spec_validate: the Makefile, the script, and the guard pin one OpenSpec version".
- [x] 1.2 `tools/agent_guard.sh`, `judge`: the contributor's `npx` admits only the pinned package. Tested by "guard: contributor refuses npx of OpenSpec at latest", "guard: contributor refuses npx of OpenSpec unversioned", "guard: contributor refuses npx of another OpenSpec version", and the contributor's propose and archive cases on the pinned package.

## 2. Run the base's scope script in CI

- [x] 2.1 `.github/workflows/ci.yml`, the `Scope` step: run `tools/ci_scope.sh` and `tools/rules.sh` from the merge commit's first parent. Tested by "ci workflows: the scope step runs the base's scope script over a head that replaces it".

## 3. Documents and self-check

- [x] 3.1 CLAUDE.md's OpenSpec line, README.md's OpenSpec row, `docs/architecture.md` section 10, and `docs/codebase-map.md` area 1.
- [ ] 3.2 Self-check: `make tools-test`, `make gates`, `make docs-lint`, and `make spec-validate` pass.
