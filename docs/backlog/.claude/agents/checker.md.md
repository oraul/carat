# Backlog: .claude/agents/checker.md

## delivery-speed quality advisory at .claude/agents/checker.md:3

- Where: `.claude/agents/checker.md:3`. Delivery review of `delivery-speed` (quality advisory) at 2dcfd3d.
- Why it matters: the description still says the checker runs the canonical stage list.
- Fix outline: say the fast stages (FAST_STAGES).
- Category: pipeline
- Added: 2026-11-11

### Remove the hooks' temporary repository on interruption

- Location: .claude/agents/checker.md:12 and every agent hook line (quality advisory, cleanup on interruption).
- Why: the temporary repository is removed only on the normal path, with no trap, so a hook killed during its fetch of about a second leaves a directory under TMPDIR on every such call.
- Fix: add trap 'rm -rf "$d"' EXIT after mktemp if the byte budgets allow, or accept it and say so in the design's Risks.
- Category: pipeline
- Added: 2026-11-14

### The checker agent costs far more than the verdict of run_state.sh check (markdown-reading-d retro)
- Location: `.claude/agents/checker.md`; `.claude/workflows/deliver-change.js` check phase
- Why: markdown-reading-d's check took 35,360 output tokens in 4 calls, 13.0% of the run's 272,795 output, for a verdict the script gives; first-pass check 136 of 138; ux-fixes-a 22,463 and palette-narrow 40,656 also over 20,000 on a first pass against a last-10 median of 6,425. For `check-skip`.
- Fix: run the check script from the workflow without an agent, or cap the agent; accepted when over the next 5 deliveries a first-pass check costs at most 5,000 output tokens and 4 calls, the stage records and first.check unchanged.
- Also: .claude/workflows/deliver-change.js
- Category: pipeline
- Added: 2026-11-17

### Passing check starts vary from 1,598 to 150,693 output tokens (T1 efficiency)
- Location: `.claude/agents/checker.md`
- Why: motions-search-tidy check 57,058 output tokens and 10 calls for two passing checks (14.0 percent of 407,893 output on 5.3 percent of 188 calls); 6 of the last 21 rows over 35,000 against a median of about 6,700; check first pass 143/145, no decision changed.
- Fix: a passing check reports from its stage logs without further reading; accepted when over the next 5 runs every passing check start costs under 12,000 output tokens.
- Category: pipeline
- Added: 2026-11-17

### The check and merge phases spend a third of a feature run's output waiting
- Location: `.claude/agents/checker.md`, `.claude/agents/merger.md`, `.claude/workflows/deliver-change.js:126` (mergerCap); backlog queue item `merge-output-cap`
- Why: facet-palette check 123,463 output in 6 calls (16.8 percent, 3 passes all green first), merge 101,948 in 13 calls (13.8 percent, ci_wait_calls 6), together 30.6 percent of output for 8.4 percent of calls; guide-colors merge 26,423 in 11 calls (facet-palette retro 12).
- Fix: the checker and merger read the stage and CI results the run state holds and generate little; accepted when check stays under 10,000 output per pass and merge under 30,000 over the next 5 feature runs with first passes unchanged. Fold into `merge-output-cap`.
- Also: .claude/agents/merger.md, .claude/workflows/deliver-change.js
- Category: pipeline
- Added: 2026-11-18

### Feature-lane check phase costs several times the backlog lane's
- Location: .claude/agents/checker.md (the checker start's reading of stage logs)
- Why: finder-grep-b spent 32,288 output tokens over 6 calls on two checks that both passed, about 16,000 per start; the feature lane's last 10 check phases run 4,693 to 153,640 (median about 28,900) against the backlog lane's 1,754 to 23,774 (median about 5,500); check first pass 179/189 (finder-grep-b retro note 11).
- Fix: keep a check whose stages all pass under 8,000 output tokens per checker start over the next 5 rows of each lane, first-pass detection unchanged.
- Category: pipeline
- Added: 2026-11-20
