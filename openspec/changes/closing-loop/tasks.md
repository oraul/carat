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

## 5. Review fixes

- [x] 5.1 `deliver-change.js`: one `capKind` for the closing start's phase figures, cap line, and cap (the line no longer reads NaN); tested by the closing cap case of `tools/tools_test.sh`.
- [x] 5.2 `deliver-change.js`: the closing figures are held before the re-review and recorded by a forced flush after it, so a resume before the push finds them and starts no second closing start; tested by the restart and figures cases.
- [x] 5.3 `deliver-change.js`: a closing start that commits nothing resets the offered findings (`awaiting`); tested by the nothing-committed case.
- [x] 5.4 `tools/tools_test.sh`: the fresh-offer, rework, and package-order cases run `freshOffers`, `contributor`, and `readyToPackage` over stubs instead of grepping the source.
- [x] 5.5 README.md, `docs/contributor-notes.md`, `docs/codebase-map.md`: the security rerun and the closing-loop helpers worded as the code behaves.
