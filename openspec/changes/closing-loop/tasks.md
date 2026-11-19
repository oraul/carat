# Tasks

## 1. Workflow

- [x] 1.1 `.claude/workflows/deliver-change.js`: `closeAdvisories`, `openAdvisories`, `closingTask`, the `closing` cap, the `closingLoop` flag in `rounds`, the package step call, the figures in `metricLine` and `seed`. Checked by the closing-loop tools-test cases.
- [x] 1.2 `tools/run_state.sh`: `advisories_closed` and `advisories_left` columns after `weighted_phases`. Checked by the history tools-test case.

## 2. Agent and notes

- [x] 2.1 `.claude/agents/contributor.md` and `docs/contributor-notes.md` (Closing); README.md and `docs/codebase-map.md`. Checked by `make docs-lint` and the mode tools-test case.

## 3. Tests

- [x] 3.1 `tools/tools_test.sh`: one closing start with its re-review and figures, the skip, no second loop, the security review of a code-changing commit, the settled records-only commit, the metric line, the history columns, and the caps. Checked by `make tools-test`.

## 4. Checks

- [x] 4.1 Run `make spec-validate`, `make gates`, `make docs-lint`, and `make tools-test`, all pass.
