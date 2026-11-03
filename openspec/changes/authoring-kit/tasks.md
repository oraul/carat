# Tasks

## 1. Shared patterns and docs-lint

- [x] 1.1 Move the forbidden-content patterns and `scan` from `tools/gates.sh` into `tools/rules.sh`; verify with `make tools-test`.
- [x] 1.2 Add `tools/docs_lint.sh` (budgets, content, hard wraps, dead paths) with its tests in `tools/tools_test.sh`; verify with `make tools-test`.
- [x] 1.3 Add `make docs-lint` to the Makefile and to `CHECK_STAGES` after `doctor`, and a CI step; verify with `make docs-lint` and `make stages`.

## 2. Generators

- [x] 2.1 Add `tools/new.sh` with the five kinds and their refusals, and the five `make new-*` targets; verify with `make tools-test`.
- [x] 2.2 Run all five generators in a scratch worktree, then `make gen-config`, `make lint`, `make test-build`, and `make test-run` there; verify every test passes and discard the worktree.

## 3. Notes and examples

- [x] 3.1 Add `docs/spinel-notes.md` with every pitfall from `CLAUDE.md`, `docs/architecture.md`, and `docs/backlog.md`; verify with `make docs-lint`.
- [x] 3.2 Add `docs/examples.md` with one golden example and checklist per kind; verify with `make docs-lint` (every path exists).

## 4. Slimming

- [x] 4.1 Slim `CLAUDE.md` to the 30 KiB budget by pointing to the notes, the examples, and `make help`; verify with `make docs-lint`.
- [x] 4.2 Slim `docs/architecture.md` sections 2.1 and 10 by pointing to the notes, and set its budget; verify with `make docs-lint`.
- [x] 4.3 Slim `.claude/agents/contributor.md` and point it at the examples, the generators, and the notes; verify with `make docs-lint`.

## 5. Docs and checks

- [x] 5.1 Update the code map (area 1 and area 18 entries for the new tools and docs), `CLAUDE.md` Commands and Layout, and `README.md`; verify with `make lint` and `make gates`.
- [x] 5.2 Record the generator compile check in `docs/backlog.md`; verify by reading it.
- [x] 5.3 Run `make check`; verify every stage passes.
- [x] 5.4 Record the sizes before and after in `design.md`; verify with `wc -c`.
