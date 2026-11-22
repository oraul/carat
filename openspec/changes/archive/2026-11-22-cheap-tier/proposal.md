# Proposal

## Why

The bookkeeping starts of the delivery and sprint workflows run a fixed command and read back its output, yet they run on the session's model with no agent file: about 0.3M weighted tokens a delivery and 0.5M a sprint close (the queue entry). They run unguarded too, so nothing but their prompt keeps them to the commands they are handed. The merger's step 7 deletes the remote branch, which the repository already deletes on merge, so the delete is refused (#300) and costs a call. And #307's squash commit 8b8e44e ended with the co-author trailer followed by a stray double quote: the merge tool's hook would have refused that message (its comparison decodes it to the same quote), so the merge did not pass through that check, and nothing in the merge phase noticed before `merged` was recorded (merge-path-lows retro note 2). By the user's decision of 2026-11-22, answer (A).

## What Changes

- A new agent file `.claude/agents/runner.md`: Bash only, its `model:` line naming the cheapest tier's short alias, its PreToolUse hook running main's `tools/agent_guard.sh` with a new `runner` profile.
- `tools/agent_guard.sh` adds the `runner` profile: the forms every profile has, plus `make doctor` and `make toolchain`, and `sh tools/run_state.sh` with `show`, `get`, `trusted`, `plan-needed`, `review-due`, `lane-open CHANGE BRANCH`, `init CHANGE BRANCH`, the workflow's records `phase`, `review`, `note`, `metric`, `ci-stages`, and `set CHANGE records skip`; no `tools/gates.sh`, no file write.
- `.claude/workflows/deliver-change.js` starts the resume and record starts as `runner`, their `CALIBRATION` profiles moving from `session/low` to `agent/low`; `.claude/workflows/sprint-planning.js` starts its due, record, and records-merged starts as `runner` at low effort; its notes and skeptic notes starts, whose commands carry finding text that quotes reviewed code, stay on the quality reviewer's record mode under the guard's `read` profile, which records notes and no review or phase (the change's security review, Medium at confidence 5).
- The merger no longer deletes the remote branch: step 7 of `.claude/agents/merger.md` drops `ls-remote` and `git push origin --delete`, keeping the local cleanup (`lane-close`, main fast-forwarded, the local branch deleted), and the guard's `merger` profile no longer allows `git push origin --delete`.
- `tools/run_state.sh` refuses to accept a merged commit (`set CHANGE merged`, and the `merged` word of `phase`) whose message's last line is not exactly `Co-Authored-By: Claude <noreply@anthropic.com>`, so the merge phase reports such a squash commit before `merged` is recorded; history on main is not rewritten.
- `tools/tools_test.sh`: cases for each start's tier and agent, the runner profile's allowed and refused forms, the merger's refused remote delete, the refused merged commit with a stray quote after the trailer, and two merge-tool guard cases with that quote.
- `docs/goals.md` Calibration notes the move; `README.md` and `CLAUDE.md` name the runner among the mechanical, guarded agents.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None: the change alters the delivery pipeline, which no spec under `openspec/specs/` describes (`skip_specs: true`).

## Impact

- `.claude/agents/runner.md` (new), `.claude/agents/merger.md`, `.claude/workflows/deliver-change.js`, `.claude/workflows/sprint-planning.js`, `tools/agent_guard.sh`, `tools/run_state.sh`, `tools/tools_test.sh`, `docs/goals.md`.
- README.md: changed, the mechanical agents of the pipeline section.
- CLAUDE.md: changed, the Agents line of guarded agents that never edit.
- docs/architecture.md: unchanged, it does not describe the delivery agents.
- docs/codebase-map.md: unchanged, the sprint notes keep the quality reviewer's record mode its flow line names; it maps no file under `.claude/`, so the new agent file adds no row.
- docs/compatibility.md, docs/actions.md: unchanged, no editor behavior changes.
- `tools/rules.sh`: not edited.

Outside the roadmap of `docs/architecture.md` section 12: a pipeline efficiency change (T1) by the user's request, the third Sprint 29 backlog item under the user-approved exception of 2026-11-22.

Minor assumptions: "the commands you listed" are the commands each handed start's prompt names, read from the two workflows; the notes starts are sprint-planning's security notes and skeptic notes starts, which the security review moved back to the read profile (a deviation from the answer's list, named in the design); the trailer check sits where the merge phase accepts the merged commit (`merged_at`), since the hook's own comparison already refuses the message, which the two new guard cases show; the runner's `maxTurns` is the larger of the resume and record caps at a large estimate plus the margin.

## Out of scope

- The keep-or-revert decision over the next 5 rows, which the planner makes from the history.
- The planner, quality, security, close, checker, benchmark, and merger tiers; `periodic-review.js`'s record start; `tools/rules.sh`; the feature lane's files; rewriting 8b8e44e on main.
