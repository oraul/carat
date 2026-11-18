# Proposal

## Why

Over the last 24 deliveries a change averaged 1,091,490 total tokens and 183,053 output tokens; the plan took 8.0 percent, the scouts 16.1, the merge 7.0, and the package step 5.7, and part of each is spent on work that changes no decision. The secret-patterns retrospective (notes 5 to 7) found the planner run on a placed, estimated first item that it left as it was (plan 11,077 output tokens, 8.7 percent), a current area pack scouted again for one missing location (scout 42,854, 33.6 percent, 1.34 times implement), and a first-pass green CI overrun the merge cap (16 calls of 14) by its waits alone. Two package steps edited reviewed files and had their push refused (motions-search-tidy, record-squash-commit), and docs-lint failed ruby-structure-remove's check on paths its own queue item named. The brief (`brief.md`) asks for six cuts in two parts; this is part a, cuts 1, 2, and 5.

## What Changes

- Plan (`plan-skip-placed`): `tools/run_state.sh plan-needed` asks for the planner when the change heads its lane queue but its item names no estimate, and no longer counts a pending change's notes once a sprint's records change merged after it, since that sprint's planner placed them. A placed, estimated first item with no unplaced note is taken as written (planned=0); the package step still removes the item.
- Scout (`scout-pack-reuse`): an area pack whose files read are unchanged at the head is reused even when it lacks some of the change's locations; the locations it lacks, and every location of an area whose paths the brief names, go to the contributor to read itself, and that area starts no scout (`scoutTargets`, `PACK_CURRENT`, the areas schema's `unread` list, `.claude/agents/scout.md` step 3).
- Merge (`merge-cap-ci-wait`): the merger's cap is a fixed 10 calls of work plus 2 for every CI wait, so a first-pass green CI that waits three times is held to 16, not 14 (`mergerCap`, `.claude/agents/merger.md`, its `maxTurns` 29).
- Package (`package-advisory-edit`): `tools/run_state.sh reviewed-edits CHANGE` lists the files changed since the commit the security review passed at outside the records-only paths and exits 1 when there are any; the contributor's package step runs it before each commit and restores such an edit, recording the finding instead, and runs `plan-apply` before it edits a lane queue; the guard lets the contributor run it.
- Docs-lint (`lint-own-queue-paths`): `tools/docs_lint.sh` does not fail a backticked path on the line of the lane queue item that names the change being checked, the change read from `DOCS_LINT_CHANGE` or the branch name.
- `tools/tools_test.sh` cases for each.

Out of scope, part b (`pipeline-diet-b`): cut 3 (the check without a relay checker start), cut 4 and 4b (the quality first pass for every blocking finding, the narrowed re-review, fix in place), and cut 6 (`records-budget-scope`), whose pool line stays for part b's package step. The security review is not touched and still runs on every change. `tools/rules.sh` is not edited. No file of the feature lane is touched.

## Figures

This part's own total and output tokens, against the 1,091,490 / 183,053 averages, are its history row in `docs/metrics-backlog.tsv` and the figures the package step reads from `sh tools/run_state.sh budget` (filled below at the package step); the next two deliveries' figures are read by the retrospective.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None: the delivery pipeline is described by no spec under `openspec/specs/` (`skip_specs: true`).

## Impact

- `tools/run_state.sh`, `tools/docs_lint.sh`, `tools/agent_guard.sh`, `.claude/workflows/deliver-change.js`, `.claude/agents/contributor.md`, `.claude/agents/merger.md`, `.claude/agents/scout.md`, `tools/tools_test.sh`.
- README.md: changed, the planner and scout paragraphs say when the planner and a scout are skipped.
- docs/codebase-map.md: changed, the `run_state.sh` and `docs_lint.sh` entries name `reviewed-edits` and the own queue item; no file is added, moved, or removed.
- CLAUDE.md: unchanged, its Agents section says the planner runs only when `plan-needed` finds a decision and states no scout, merge-cap, or package-step detail this change alters.
- docs/architecture.md: unchanged, it does not describe the delivery pipeline's phases.
- docs/compatibility.md and docs/actions.md: unchanged, no editor behavior.

Outside the roadmap of `docs/architecture.md` section 12: a pipeline efficiency change of the backlog lane, item 2 of the autonomy plan, counted as a sprint backlog item by the user's decision.
