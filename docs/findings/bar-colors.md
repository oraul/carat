### The merge phase's output on a green first-pass CI varies fivefold
- Location: `.claude/agents/merger.md`, the merge phase of `.claude/workflows/deliver-change.js` (palette-narrow note 3, check-parallel note 8).
- Why: palette-narrow's merge took 69,031 of 304,750 output tokens (22.7%) in 11 calls with ci:1 and 4 CI wait calls; check-parallel's 22,685 in 11 calls; of the last 20 lane rows 19 passed CI first, 6 of them over 10,000 (up to 39,463) against a median near 7,100.
- Fix: make one CI wait and one merge cost about the same each run; accepted when the merge phase stays under 8,000 output tokens in 4 of the next 5 runs whose CI passes first.

### The checker's start costs as much as a fix round on a first-pass check
- Location: the check phase of `.claude/workflows/deliver-change.js`, `.claude/agents/checker.md` (palette-narrow note 4).
- Why: palette-narrow's check took 40,656 of 304,750 output tokens (13.3%) in 8 calls for a pass at the first try, while check first pass is 130 of 132 changes and 6 of the last 10 feature rows' check phase ran under 6,200.
- Fix: remove or merge the checker start so a passing check costs little; accepted when a first-pass check costs under 6,000 output tokens in 4 of the next 5 runs and a failing stage still returns to the contributor.

### The check-pass budget step returns nothing or reads under (same proposal as budget-prediction)
- Location: the check-pass budget step of `.claude/workflows/deliver-change.js` (palette-narrow note 4, check-parallel note 9).
- Why: check-parallel's step printed no spent line; palette-narrow's read under at 178,345 because it counted no phase from check on, which then added 126,405 (41%); the projection assumes 6 total tokens per output token while the last ten backlog rows ran 3.5 to 59.
- Fix: drop the step or fold it into the close budget line; accepted when over the next 5 runs every budget step prints an under: or over: line, or the close line is the only one.

### Quality advisories the package step drops as style (same proposal as review-demotion)
- Location: `.claude/agents/quality-reviewer.md` (check-parallel note 10).
- Why: check-parallel dropped 4 of 7 advisories as style-only, 1 fixed, 2 appended; sprint-security dropped 3 of 6; reviews 26,694 output (11.1%) and 26 of 133 calls; quality first pass 67/131.
- Fix: the reviewer does not report a class the contributor then drops unchanged; accepted when over the next 5 runs the package step drops none of the advisories reported.
