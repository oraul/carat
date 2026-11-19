# Tasks

## 1. Card and checklist

- [x] 1.1 `.claude/agents/contributor.md`: the ten-rule card at the top and the self-check naming the checklist points and the self-review; prose moved to `docs/contributor-notes.md`. Checked by `make docs-lint` budgets and the tools-test cases of 2.1.
- [x] 1.2 `.claude/workflows/deliver-change.js`: `CONTRIBUTOR_CARD` appended in `contributorTask`. Checked by the tools-test card case.
- [x] 1.3 `docs/contributor-notes.md` and its place in `docs/codebase-map.md`. Checked by `make docs-lint` and `make lint`.

## 2. Tests

- [x] 2.1 `tools/tools_test.sh`: the card is equal in the agent file and in every mode's prompt; the self-check names each point. Checked by `make tools-test`.

## 3. Checks

- [x] 3.1 Run `make spec-validate`, `make gates`, `make docs-lint`, and `make tools-test`, all pass.
