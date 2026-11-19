# Tasks

## 1. Recording a first-pass miss

- [x] 1.1 `.claude/agents/quality-reviewer.md`: the first pass reads each file to its end; a later blocking finding on lines unchanged since the last review carries `first-pass miss`. Verified by `make docs-lint`.
- [x] 1.2 `.claude/workflows/deliver-change.js`: `firstPassMiss` and the note in the quality handler. Tested in `tools/tools_test.sh` by "workflow: a blocking quality finding on unchanged lines is noted as a first-pass miss".
- [x] 1.3 Self-check: `make gates`, `make docs-lint`, `make spec-validate`, and `make tools-test` pass.
