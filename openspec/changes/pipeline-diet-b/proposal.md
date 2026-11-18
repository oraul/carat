# Proposal

## Why

Over the last 24 deliveries a change averaged 1,091,490 total tokens and 183,053 output tokens, the reviews 15.0 percent and the check 6.9. The checker start reads and reports every check, though the workflow decides only from the verdict line; vim-folds-a needed three quality rounds because its six blocking findings were found one round at a time (1,678,269 tokens), and quality passes first only 84 times in 152 against the check's 149; merge-main-path (#198) recorded two security Lows in its own files that the sprint review raised as a Medium, which cost moved-review-carry (#199, 1,028,455 tokens); and every records row stood over 500,000 tokens because the sprint review's starts were counted in it (sprint-14-records 1,973,945 on 32,743 output). The brief (`brief.md`) is part b of `pipeline-diet`: cuts 3, 4, 4b, and 6, covering the pool line `records-budget-scope`.

## What Changes

- Check (cut 3): the workflow builds the check's command lines itself (`checkLines`) and gives them to a start that runs only those lines and reads nothing (the checker file's `Mode: run`, guarded, on the cheap tier); the checker's reading start (`Mode: log`) runs only on a failed stage (`checkerNeeded`), never on a pass, a refusal, or a check that did not finish.
- Quality (cut 4): the first quality pass is asked for every blocking finding it can find in the whole diff (`qualityTask`); a re-review checks the fix and the findings left; every advisory not fixed stays recorded; the security review is unchanged and runs on every change.
- Fix in place (cut 4b, the user's decision of 2026-11-18): each security finding in code the change touches, of any severity, and each quality advisory goes to the contributor once, in the same round as the blocking findings, or in a round of its own when nothing blocks and a round remains after it (`inPlaceRound`); the contributor fixes those in files the change edits whose fix stays there and adds no behavior, each a task of the change's tasks.md; the check, the security review, and the quality review run again at the new head, and the reviewers name the ones they confirm fixed (`fixed_in_place`); only those leave the findings handed to `docs/findings/<change>.md`, every other recorded, none dropped. At the last round the findings are recorded, never fixed.
- Records budget (cut 6): `tools/run_state.sh tokens` keys sprint-planning's own starts (its labels now begin `sprint:` or name a sprint, skeptic, or periodic review) as `sprint`, and `budget` of a `sprint-N-records` change subtracts their total tokens, naming them set apart; `/sprint` records the workflow's cost on the records change as `/deliver` does.
- `docs/goals.md` (the pace, price, and quality line), CLAUDE.md (Agents and the findings convention), README.md (pipeline steps 4, 5, 8, and 11), and the checker and quality reviewer files say the same.
- `tools/tools_test.sh` cases for each cut.

Out of scope: `tools/rules.sh` is not edited; `.claude/agents/contributor.md` is not touched (the fix-in-place instruction rides in the workflow's fix prompt); no file of the feature lane is touched.

## Figures

The run state's figures before the implement step: 366,680 total tokens recorded by earlier starts of this run (the first run's stop included), against the 1,091,490 total average; its output tokens and the final total are filled at the package step from `sh tools/run_state.sh budget pipeline-diet-b`, against the 183,053 output average.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None: the delivery pipeline is described by no spec under `openspec/specs/` (`skip_specs: true`).

## Impact

- `.claude/workflows/deliver-change.js`, `.claude/workflows/sprint-planning.js`, `.claude/agents/checker.md`, `.claude/agents/quality-reviewer.md`, `.claude/commands/sprint.md`, `tools/run_state.sh`, `tools/tools_test.sh`, `docs/goals.md`.
- README.md: changed, the checker, quality, rounds, and sprint paragraphs.
- CLAUDE.md: changed, the Agents section and the findings convention say findings in the change's own files are fixed in place and re-reviewed, the rest recorded.
- docs/architecture.md: unchanged, it does not describe the delivery pipeline's phases.
- docs/codebase-map.md: unchanged, no file is added, moved, or removed, and its entries for these files name no detail this change alters.
