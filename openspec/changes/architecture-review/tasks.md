# Tasks

## 1. Review

- [x] 1.1 Check `docs/architecture.md` and `docs/codebase-map.md` against the code at main and write the Findings section of `openspec/changes/architecture-review/design.md`: holes, redundancy, reading and maintenance costs, each with location, why, and fix outline, and the corrections made here. Verify every named location exists with `grep`/`find` over the named paths, never `docs/backlog.md`.

## 2. Corrections

- [ ] 2.1 `docs/architecture.md`: correct each disagreement the report lists under Corrected here (planned markers, layer diagram, ex commands, API version, `Carat::Json` size, Makefile role, port callers, environment reads, completion menu, layout tree, roadmap condition). Verify with `make docs-lint` and `make test-one T=test/lint.rb` (the port table and the map paths).
- [ ] 2.2 `docs/codebase-map.md`: correct area 17's environment reads, area 4's repeated method, and area 1's stray mark. Verify with `make test-one T=test/lint.rb` (map methods and paths) and `make docs-lint`.

## 3. Backlog

- [ ] 3.1 Append every open finding of the report to the end of `docs/backlog.md` with `>>`, without reading the file. Verify with `git diff --stat docs/backlog.md` (additions only) and `make docs-lint`.

## 4. Gates

- [ ] 4.1 Run `make gates` and `make spec-validate` and fix what fails.

## Workflow follow-up

- Archive with `openspec archive architecture-review -y --skip-specs`, which keeps the design and its Findings in the archived change.
