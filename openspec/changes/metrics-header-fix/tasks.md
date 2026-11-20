# Tasks

## 1. Queue

- [x] 1.1 Add the user-approved exception line under the Sprint 23 heading of `docs/queue-backlog.md`; checked by `make docs-lint` (queue)

## 2. Row writer

- [x] 2.1 Make `append_history` in `tools/run_state.sh` refuse a non-empty lane file whose line 1 differs from `HEADER`, before any append, and write `HEADER` into an absent or empty one; proved by "run_state: history refuses a lane file whose header is short of HEADER", "run_state: history appends no row under a header short of HEADER", "run_state: history refuses a header ending in a carriage return", "run_state: history writes the header into an empty lane file", and "run_state: the row under the header has its field count" in `tools/tools_test.sh`

## 3. Histories

- [x] 3.1 Rewrite line 1 of `docs/metrics-feature.tsv` and `docs/metrics-backlog.tsv` to `HEADER` and pad each 22-field row with two `-` fields, no other field changed; checked by the docs-lint `histories` check of task 4.1 and a `git diff --numstat` of 64 and 125 changed lines

## 4. docs-lint

- [x] 4.1 Add `check_histories` to `tools/docs_lint.sh`; proved by "docs_lint: passes histories whose rows have their header's field count" and "docs_lint: refuses a history row whose field count differs from its header's and names it" in `tools/tools_test.sh`, and by `make docs-lint` on this tree

## 5. Docs

- [x] 5.1 Update the comment above `append_history`, the usage header of `tools/docs_lint.sh`, the header comment of `tools/tools_test.sh`, the README's docs-lint line and documents paragraph, and the map's `tools/run_state.sh` and `tools/docs_lint.sh` entries; checked by `make docs-lint` and `make gates`
- [x] 5.2 Write `HEADER` (`HISTORY_HEADER`) as line 1 of the sprint, budget, and bench fixtures of `tools/tools_test.sh` that wrote a placeholder, since history now refuses one; checked by `make tools-test`
- [x] 5.3 Run `make tools-test`, `make docs-lint`, `make gates`, and `make spec-validate`
