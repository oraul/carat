# Proposal

## Why

The user asked, on 2026-11-22, that the main session's standing rules be inside the repository and not in a session, so every session and agent follows the same text. Six rules were held only in conversation: never stop a running delivery; resume a stopped run with its run id and the same args, never amending a brief once its run started; report both total and weighted tokens; keep the contributor on its agent file's tier at high effort; follow the user's instructions as written with short replies and questions about improvements; and run the after-merge routine.

## What Changes

- `CLAUDE.md`: a new `## Main session` section before `## Stack` holds the six rules in one line each. The file had 15 bytes of room under its 30,720-byte docs-lint budget, so the section is paid for by tightening existing prose, no rule dropped: the branch types table became one sentence, the branch examples line, the short-lived branches bullet, the "branch from main" bullet, the commit-message bullet restating the hard rules, the "branch commits do not survive" bullet, a sentence on what the PR number links, a clause on the subject line, and the telemetry clause outside Claude Code went, and the breaking-change bullet lost its example. The budget is not raised.
- `docs/goals.md`: a new `## Main session` section before `## Critical changes` holds each rule with its reason and the detail the short form leaves out.
- Each rule's place: (1) never stop a running delivery, `CLAUDE.md` Main session first bullet and `docs/goals.md` Main session first bullet; (2) resume with the run id and the same args, no brief amended after the run started, the same bullets, `docs/goals.md` second bullet; (3) total and weighted tokens, `CLAUDE.md` second bullet and `docs/goals.md` third bullet; (4) the contributor's tier, `CLAUDE.md` third bullet and `docs/goals.md` fourth bullet, citing Calibration, `contributor-tier-fixed`, which already fixes it; (5) the user's instructions as written, `CLAUDE.md` fourth bullet and `docs/goals.md` fifth bullet; (6) the after-merge routine, `CLAUDE.md` last bullet, consistent with the Sprints line of Agents (the main session starts `/sprint`, which runs `review-due`), and `docs/goals.md` last bullet with the commands.

Outside the roadmap of `docs/architecture.md` section 12: a user-requested process change, a backlog-lane item placed by the planner by the user's exception.

Out of scope: any change to `tools/`, the workflows, or the agents; `tools/rules.sh` is not edited; the feature lane's files are not touched.

Minor assumptions: rules 2, 3, and 6 are written so they do not claim `usage` or `tokens` succeed after a resume under the same run id, a known defect (pool items `resume-tokens-id` and `stopped-total-unset`), and the tooling side of rule 2 (`plan-brief-amend`) stays queued; the rules record how the main session behaves, so no test proves them beyond `make gates` and `make docs-lint`.

## Capabilities

### New Capabilities

None: a process-document change with no spec; `skip_specs: true`.

### Modified Capabilities

None.

## Impact

- `CLAUDE.md`, `docs/goals.md`.
- README.md: unchanged, it describes the delivery pipeline and the product, not the main session's conduct.
- docs/architecture.md: unchanged, the roadmap and layers are not touched.
- docs/codebase-map.md: unchanged, no file is added, moved, or removed.
