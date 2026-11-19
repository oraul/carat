# Design

## Context

See proposal.md, Why. The workflow passes no model to a start: an agent start runs on its agent file's `model:` line when it has one, else on the session's model, and `calibrate` passes only the effort. `CALIBRATION` records the tier as a label beside each kind, and `tools/tools_test.sh` checks that the label matches whether the agent file has a `model:` line. Four files carry the cheapest tier's alias today; the contributor will be the first on the mid tier.

## Goals / Non-Goals

**Goals:**

- Contributor starts run on the mid tier and record `calib.contributor=agent/session` in the run state.
- No calibration profile claims a mid-tier start is cheap: the workflow's `CALIBRATION`, the run state's `calib.KIND`, and the history's `calibration` column. The token labels `tools/run_state.sh` writes (`metric.start.N` and `weighted_phases`) still call a start on any agent file's alias `cheap` until the queued `tier-price-mid` change; recorded as a finding.

**Non-Goals:**

- Pricing and labelling tokens by tier in `tools/run_state.sh` (the queued `tier-price-mid` finding).
- Moving any other kind.

## Decisions

- Rename the label to `agent` instead of adding a `mid` label. A `mid` label would need tools-test to know which alias is mid, naming an alias outside an agent file's frontmatter, which CLAUDE.md forbids; `agent` keeps the comparison exactly as it is (a `model:` line means the `agent` tier), and the agent file stays the only place the tier is named.
- Change the four places that accept a profile together (`CALIBRATION`, `restoreCalibration`, the metric line's filter, and the two tools-test patterns), so a profile the table writes is never dropped before the run state stores it.
- Accept only the new label on restore, with no alias for `cheap`: the window is a run in flight across this merge, and a dropped profile is recorded again when its kind next starts.
- Effort stays `session` for the contributor: the trial measures the tier alone.

## Risks / Trade-offs

- [The mid tier passes fewer first quality reviews or needs more rework] → the goals note's revert rule: over the next 6 deliveries against the last 10 rows, any of the four figures worse queues the revert.
- [Weighted tokens understate a mid-tier start] → recorded as a finding; the verdict reads total tokens.
- [contributor.md is at its byte budget] → two wording trims offset the frontmatter line; the budget is not raised.

## Migration Plan

Takes effect at the first delivery started after the merge. Revert: drop the `model:` line, set the contributor back to `session/session`, and drop the tools-test check "calibration: the contributor runs on its agent file's tier at the session's effort", which would fail otherwise.
