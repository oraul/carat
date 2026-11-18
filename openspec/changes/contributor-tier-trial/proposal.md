# Proposal

## Why

The user asked for a trial of normal delivery work on the mid model tier, the reviews and sprint planning staying on the session's model (2026-11-18, "For the contributor"). Today every contributor start runs on the session's model, the largest share of a run's tokens, and the calibration table's only non-session tier is labelled `cheap`, so moving the contributor onto its agent file's tier would record a mid-tier start as cheap.

This change is outside the roadmap of `docs/architecture.md` section 12: it calibrates the delivery pipeline, a user-requested trial taken off the queue at bb7ed42 as a user-approved exception in the backlog lane.

## What Changes

- `.claude/agents/contributor.md` gets a `model:` frontmatter line naming the mid tier's short alias, the one place CLAUDE.md lets a tier be named; two wording trims keep the file within its 6,999-byte budget.
- `CALIBRATION` in `.claude/workflows/deliver-change.js` moves the contributor alone from `session/session` to `agent/session`: the agent file's tier at the session's effort.
- The tier label `cheap` becomes `agent` ("the tier the agent file's `model:` line names"), so a mid-tier start is not recorded as cheap; the table, `restoreCalibration`, the metric line's filter, and the tools-test checks accept `(agent|session)/(low|session)` alike, and the test keeps comparing the `agent` tier with the agent files' `model:` lines.
- `tools/tools_test.sh` checks the new label everywhere it checked `cheap`, that the contributor's profile is `agent/session`, and that the planner, quality, security, and close starts keep the session's tier.
- `docs/goals.md`, Calibration: the label, older rows' `cheap` read as `agent`, and the trial with its revert rule: kept only if over the next 6 deliveries the quality first pass, rework rounds, CI fixes, and total tokens are no worse than over the last 10 rows, else reverted.
- `README.md`: the pipeline paragraph says the contributor runs on the mid tier during the trial.
- `docs/findings/contributor-tier-trial.md`: the planner's finding that `tools/run_state.sh tokens` prices a mid-tier start at the cheap tier's price.

## Capabilities

### New Capabilities

None: the change alters the delivery tooling, not the editor's behavior (`skip_specs: true`).

### Modified Capabilities

None.

## Out of scope

- The retrospective (close), quality reviewer, security reviewer, planner, and every sprint-planning and periodic-review start keep the session's model, by the user's decision; the security reviewer never moves.
- The token weighting of `tools/run_state.sh tokens` (`TIER_PRICES`, its `cheap` price label): recorded as a finding, not fixed here; the trial's verdict uses total tokens, which it does not touch.
- `tools/rules.sh` is not edited: its model-line rule already allows the mid tier's alias.

## Assumptions

- The tier label is renamed rather than documented, since `cheap` would mislabel a mid-tier start in every later history row; older rows keep `cheap`, which the goals note reads as `agent`.
- A restart of a run started before this merge drops a `cheap/...` profile it recorded, as any value outside the table's form; it is re-recorded when that kind starts again.
- The contributor keeps the session's effort; only its tier moves.

## Impact

`.claude/agents/contributor.md`, `.claude/workflows/deliver-change.js`, `tools/tools_test.sh`, `docs/goals.md`, `README.md`, and `docs/findings/contributor-tier-trial.md`.

- README.md: changed, the pipeline paragraph names the contributor's tier.
- docs/architecture.md: unchanged, it describes no agent's model tier or the calibration table.
- CLAUDE.md: unchanged, its Agents section describes each agent's role and never its model tier, which the agent file and `docs/goals.md` hold.
