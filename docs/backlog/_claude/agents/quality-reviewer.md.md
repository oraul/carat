# Backlog: .claude/agents/quality-reviewer.md

### The quality reviewer raises blocking parity bugs one round at a time (vim-folds-a retro 24)

- Location: .claude/agents/quality-reviewer.md and the quality phase of .claude/workflows/deliver-change.js.
- Why: vim-folds-a's later rounds raised blocking findings on behavior present at the first review (G or a mark leaving the cursor inside a closed fold; o on a closed fold): rework 3, implement 266,825 of 481,959 output tokens (55.4%) over 4 contributor starts; quality first pass 80/147 (54.4%), the lowest gate.
- Fix outline: the first review reports every blocking finding in the touched behavior; accepted when over the next 5 runs with first.quality 0 no later round raises a blocking finding on code unchanged since the first review.
- Also: .claude/workflows/deliver-change.js
- Category: pipeline
- Added: 2026-11-17

### A re-review re-raised an advisory declined for the brief's reason
- Location: `.claude/agents/quality-reviewer.md`, `.claude/workflows/deliver-change.js` (notes handed to a later round); facet-palette note 6 repeating note 1
- Why: the PANEL_DIM advisory, declined in round 1 because the brief pins #a4aabd / #5c6173, came back word for word; round 2 grew output from 332,067 to 573,120 (+241,053, 33 percent of 736,922); quality first pass 93/166 (facet-palette retro 11).
- Fix: an advisory declined with a recorded reason goes to the findings file, not to a new round; accepted when no run has a later-round advisory repeating a declined note that drives a round of its own. Fold into `rework-review-repeat`.
- Also: .claude/workflows/deliver-change.js
- Category: pipeline
- Added: 2026-11-18

### Marker refers to the wrong review commit
- Location: .claude/agents/quality-reviewer.md:21
- Why: that diff refers to the diff since the last passed review, while a blocked round's input names the last review's commit, blocked or passed.
- Fix: tie the marker to the commit the input names, the last quality review, as priorQuality words it.
- Category: pipeline
- Added: 2026-11-19

### The quality first pass misses stale wording of a replaced behavior
- Location: .claude/agents/quality-reviewer.md (finder-match-strict retro note 13)
- Why: finder-match-strict's quality first pass listed no docs-currency advisory, then 3 later passes found 5 (the old 'fuzzy' or 'unchanged' wording in docs/plugins.md, docs/compatibility.md, docs/actions.md, docs/codebase-map.md, plugin.rb, README.md); quality first pass 106 of 194 overall; reviews 45,892 output tokens and 55 of 221 calls (25%); rework 2 of 3, round 2 docs-only.
- Fix: when a change replaces a behavior, the first pass searches the tree for the replaced behavior's old wording and reports every stale mention at once; accepted when such a change shows no docs-currency advisory after its first quality pass.
- Also: docs/plugins.md, docs/compatibility.md, docs/actions.md, docs/codebase-map.md, README.md
- Category: pipeline
- Added: 2026-11-20

### The quality first pass names one occurrence of a pattern it flags (pr-trust-lows retro 8)
- Location: `.claude/agents/quality-reviewer.md`, the first-pass instructions.
- Why: the advisory at d388c4a (pin copies the test does not read) missed the guard's refusal literal at `tools/agent_guard.sh:902`, present since d388c4a and found at ee4ce6c, causing rework round 2 of 3 with every first pass 1 and 0 blocking findings; reviews 63,219 output tokens (21.0 percent) over 56 calls; quality first pass 113/205 in history. Near the backlog queue's `stale-wording-first-pass` and `rework-review-repeat`.
- Fix: the first pass searches the tree for every occurrence of a flagged pattern and names them all; accepted when over the next 5 runs no advisory names a line unchanged since an earlier quality review of the same run.
- Merged: ### The first quality pass names one occurrence of a pattern it flags (pr-trust-lows retro 8)
- Location: `.claude/agents/quality-reviewer.md`, the first-pass instruction.
- Why: pr-trust-lows' advisory at d388c4a (pin copies the test does not read) missed the guard's refusal literal at `tools/agent_guard.sh:902`, present since d388c4a and found only at ee4ce6c, costing rework round 2; the run recorded rework 3 of 3 with every first pass 1 and 0 blocking findings, reviews 63,219 output tokens (21.0 percent) over 56 calls; quality first pass 113/205. Near the backlog queue's `stale-wording-first-pass` (Pool 22) and `rework-review-repeat` (Pool 20).
- Fix: have the first pass search the branch for every occurrence of a pattern it flags; accepted when over the next 5 runs no advisory names a line unchanged since an earlier quality review of the same run.
- Also: tools/agent_guard.sh
- Category: pipeline
- Added: 2026-11-20

### The quality reviewer's steps 5 to 7 describe a delivery review no workflow starts
- Location: .claude/agents/quality-reviewer.md:22 (steps 5 to 7)
- Why: after review-in-openspec no delivery starts the quality reviewer on its diff; only the pull request text check, the sprint, skeptic, and periodic modes use the agent, and the contributor applies steps 1 to 4 itself, so steps 5 to 7 (quality-blocking and quality-advisory notes, fix in place, the hand-over) describe a path that no longer runs and could lead the text check to record notes nobody reads.
- Fix: decide whether the pull request text check records anything; then reduce steps 5 to 7 to that and to the sprint and periodic modes, and say the contributor's step records findings as tasks.
- Category: pipeline
- Added: 2026-11-21

### The quality reviewer's steps still describe the per-delivery review (sprint-25 review quality)
- Location: `.claude/agents/quality-reviewer.md:16`, `tools/run_state.sh:1652`
- Why: since review-in-openspec no delivery starts the quality reviewer for a fix round, yet its steps describe fix rounds, the scope command, fixed_in_place, and the quality-blocking and quality-advisory notes; `fix_scope` (`run_state.sh scope`) is reached only by `tools/tools_test.sh`.
- Fix: trim the agent file to its sprint, periodic, skeptic, pull request text, and self-review uses; remove `scope` with its tests and its codebase-map mention; accepted when tools-test passes and no workflow names `scope`.
- Category: pipeline

### The periodic quality reviewer records its notes as double-quoted shell arguments
- Location: `.claude/agents/quality-reviewer.md` Periodic mode step 4 (`sh tools/run_state.sh note <change> quality "<file>:<line> ..."`), run by `.claude/workflows/periodic-review.js`
- Why: a finding that quotes reviewed code holding `$(...)` or a backquote expands when the reviewer runs its own note command, the exposure pipeline-lows-a closed for the sprint skeptic (security Low class, found by its quality step).
- Fix: have the periodic quality reviewer return its findings only and let periodic-review.js record each with a `shellWord`-quoted note command, as sprint-planning.js `skepticNotes` does, with a tools-test case recording a finding holding `$(...)` literally.
- Also: tools/run_state.sh, .claude/workflows/periodic-review.js
- Category: security
- Added: 2026-11-22
