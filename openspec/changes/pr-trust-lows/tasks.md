# Tasks

## 1. Pin OpenSpec

- [x] 1.1 `Makefile` (`OPENSPEC_PACKAGE`, `OPENSPEC`), `tools/spec_validate.sh`: run `@fission-ai/openspec@2.1.1`. Tested in `tools/tools_test.sh` by "spec_validate: runs the pinned OpenSpec when no command is given" and "spec_validate: the Makefile, the script, the guard, and CLAUDE.md pin one OpenSpec version".
- [x] 1.2 `tools/agent_guard.sh`, `judge`: the contributor's `npx` admits only the pinned package. Tested by "guard: contributor refuses npx of OpenSpec at latest", "guard: contributor refuses npx of OpenSpec unversioned", "guard: contributor refuses npx of another OpenSpec version", and the contributor's propose and archive cases on the pinned package.

## 2. Run the base's scope script in CI

- [x] 2.1 `.github/workflows/ci.yml`, the `Scope` step: run `tools/ci_scope.sh` and `tools/rules.sh` from the merge commit's first parent. Tested by "ci workflows: the scope step runs the base's scope script over a head that replaces it".

## 3. Documents and self-check

- [x] 3.1 CLAUDE.md's OpenSpec line, README.md's OpenSpec row, `docs/architecture.md` section 10, and `docs/codebase-map.md` area 1.
- [x] 3.2 Self-check: `make tools-test`, `make gates`, `make docs-lint`, and `make spec-validate` pass.

## 4. Review fixes

- [x] 4.1 Quality advisory at CLAUDE.md:194 and `tools/agent_guard.sh:88`: the guard's header comment names the Makefile's `OPENSPEC_PACKAGE` instead of the version literal, CLAUDE.md's OpenSpec line joins the pins the tools test compares, and the Makefile's comment counts all four. Tested by "spec_validate: the Makefile, the script, the guard, and CLAUDE.md pin one OpenSpec version".
- [x] 4.2 Quality advisory at `tools/tools_test.sh:248`: the scope case expects `tools/base.sh`, the first path `git diff --name-only` sorts, alone.
- [x] 4.3 Quality advisory at Makefile:138: the guard's npx refusal names the Makefile's `OPENSPEC_PACKAGE` instead of the version literal, so a bump of the four pins leaves no stale version. Tested by "spec_validate: the guard names the pinned version once" and the guard's three OpenSpec refusal cases.
