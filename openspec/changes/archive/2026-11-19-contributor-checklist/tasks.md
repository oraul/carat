# Tasks

## 1. Card and checklist

- [x] 1.1 `.claude/agents/contributor.md`: the ten-rule card at the top and the self-check naming the checklist points and the self-review; prose moved to `docs/contributor-notes.md`. Checked by `make docs-lint` budgets and the tools-test cases of 2.1.
- [x] 1.2 `.claude/workflows/deliver-change.js`: `CONTRIBUTOR_CARD` appended in `contributorTask`. Checked by the tools-test card case.
- [x] 1.3 `docs/contributor-notes.md` and its place in `docs/codebase-map.md`. Checked by `make docs-lint` and `make lint`.

## 2. Tests

- [x] 2.1 `tools/tools_test.sh`: the card is equal in the agent file and in every mode's prompt; the self-check names each point. Checked by `make tools-test`.

## 3. Checks

- [x] 3.1 Run `make spec-validate`, `make gates`, `make docs-lint`, and `make tools-test`, all pass.

## 4. Review findings fixed in place

- [x] 4.1 README.md and the proposal: dropped the tier routing and effort clause, left to `contributor-tier-routing`.
- [x] 4.2 `.claude/agents/contributor.md`: restored "checker and security review" in the push mode, "or this agent", "direct your work", the `show <change>` pointer, the Report section, and "saying which no longer hold"; shortened the description and the wait timeout (moved to the notes) to stay in budget.
- [x] 4.3 Card rule 3 without the stray "Rule:" in the agent file and `CONTRIBUTOR_CARD`.
- [x] 4.4 `tools/tools_test.sh`: the checklist acceptance case lists all ten points.
- [x] 4.5 `docs/contributor-notes.md`: the conflicts section starts at "On its conflicts"; the proposal now says the notes hold the checklist's points, not cited findings; the map entry names every section.
