# Proposal

## Why

Agents spend most of their tool calls looking things up: 1,231 of the 2,130 contributor tool calls of the baseline run were reads and searches (`docs/queue.md`, Decisions). Adding a use case, a handler, an ex command, a test, or a plugin means finding a good file to copy and the five other places it must be wired into, and the Spinel pitfalls that decide whether the code compiles typed are spread over `CLAUDE.md`, `docs/architecture.md`, and `docs/backlog.md`, so every contributor reads all three. `CLAUDE.md` has grown to 41 KB with nothing holding it back. This is item 1 of `docs/queue.md` and the first change measured against the metrics baseline.

## What Changes

- Add `docs/examples.md`: one golden example per common kind (use case with `call`, action handler, ex handler, domain record, port with driver and double, plugin, table-driven test), each a small file already in the tree, with the checklist of every other place the kind is wired into and the generator that scaffolds it.
- Add `tools/new.sh` and the targets `make new-use-case`, `make new-ex-command`, `make new-action`, `make new-test`, and `make new-plugin`: shell scaffolds that write the file with its inline RBS signatures, its code map entry, its runner lines and a snapshot that already passes (tests), its require and registration lines, and its documentation row, then print the steps left to the author. No Ruby interpreter runs; `make new-plugin` regenerates the registry with `make gen-config`, the Spinel-built generator.
- Add `docs/spinel-notes.md`: every Spinel pitfall once, with its symptom, its rule, the check that enforces it, and its backlog item when one is open.
- Add `tools/docs_lint.sh` and `make docs-lint`, a new stage in `CHECK_STAGES`: size budgets (`CLAUDE.md` 30 KiB, each agent file 8 KiB, `docs/architecture.md` at its new size) and quality checks over the docs (no URL, no email address but the trailer's, no session id, no model name, no hard-wrapped pull request text, no backticked repository path that does not exist). The forbidden-content patterns move from `tools/gates.sh` into `tools/rules.sh`, which both scripts source.
- Slim `CLAUDE.md`, `docs/architecture.md`, and `.claude/agents/contributor.md` by pointing to the notes and the examples instead of repeating them, and record the sizes before and after in the design.
- Update the code map, `README.md`, and CI (a docs-lint step).

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None. This is a tooling and documentation change with no change to the editor's behavior; `skip_specs` is set.

## Impact

- New: `docs/examples.md`, `docs/spinel-notes.md`, `tools/new.sh`, `tools/docs_lint.sh`, `tools/rules.sh`.
- Changed: `Makefile`, `tools/gates.sh`, `tools/tools_test.sh`, `.github/workflows/ci.yml`, `CLAUDE.md`, `README.md`, `docs/architecture.md`, `docs/codebase-map.md`, `.claude/agents/contributor.md`.
- No file under `carat/`, `bin/`, `test/`, or `bench/` changes; the editor binary is unchanged.

This change is outside the roadmap of `docs/architecture.md` section 12: it is the tooling change the user queued first in `docs/queue.md` (goals 12 and 14 of `docs/goals.md`).

Out of scope: rewriting the rules themselves (every rule moved keeps its meaning and is still binding where it now lives); fixing any Spinel pitfall (each stays a backlog item); a compile check of generator output in `make check` (verified by hand in this change, recorded under Testing, and left in `docs/backlog.md`); generators for kinds other than the five named.

Assumptions recorded instead of asked:

- The golden examples are existing files chosen for being small and current, not new sample code: new sample code would either be dead code in the library or production behavior nobody asked for, while existing files pass lint and the tests on every run and cannot drift; `make docs-lint` fails when one is moved without updating `docs/examples.md`.
- "About 30 KB" for `CLAUDE.md` is a 30 KiB (30,720 byte) budget and "about 8 KB" per agent file is 8 KiB; `docs/architecture.md` gets a budget at its slimmed size rounded up to the next KiB so it cannot grow back unnoticed.
- `CLAUDE.md` is slimmed by moving detail, not rules: the Hard rules, Git workflow, branch, commit, and pull request sections keep their text; Spinel mechanics move to `docs/spinel-notes.md`, the wiring of each kind to `docs/examples.md`, and command details to `make help`, each with a pointer that keeps it binding.
