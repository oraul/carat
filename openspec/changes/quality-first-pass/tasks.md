# Tasks

## 1. Recording a first-pass miss

- [x] 1.1 `.claude/agents/quality-reviewer.md`: the first pass reads each file to its end; a later blocking finding on lines unchanged since the last review carries `first-pass miss`. Verified by `make docs-lint`.
- [x] 1.2 `.claude/workflows/deliver-change.js`: `firstPassMiss` and the note in the quality handler. Tested in `tools/tools_test.sh` by "workflow: a blocking quality finding on unchanged lines is noted as a first-pass miss".
- [x] 1.3 Self-check: `make gates`, `make docs-lint`, `make spec-validate`, and `make tools-test` pass.

## 2. Review fixes

- [x] 2.1 A first-pass miss is only a new blocking finding, not one the last review left blocking: `qualitySplit` in `deliver-change.js` and the agent file and README wording. Tested by "a first-pass miss is noted only for a new marked finding".
- [x] 2.2 The marker is matched right after the location, case-insensitively; the split is a pure helper tested through `speed_js`; the agent file and README say unchanged since the commit the input names as the last quality review.
- [x] 2.3 Review fixes: the prior-location filter of `qualitySplit` is tested alone (the prior finding is marked); the whole-branch input lists the last review's blocking findings; the duplicate marker case is folded; the proposal wording matches. Tested by "a first-pass miss is noted only for a new marked finding" and "the marker counts only right after the location".
