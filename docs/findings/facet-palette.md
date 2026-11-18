### Advisory-only fix rounds cost a full review round (guide-colors retro, merged)
- Location: `.claude/workflows/deliver-change.js`, the rework loop after the reviews
- Why: guide-colors reported 0 blocking findings (security 0, quality 0 blocking), yet 4 quality advisories cost rework 1: output 147,140 at the first check pass and 230,744 at the second (83,604 more), over the medium output budget of 200,000. The same finding as "### Advisory-only fix rounds cost a full review round (sprint-17-records retro)" and the `advisory-findings-auto` entry; merge into them at grooming.
- Fix: a run whose reviews report 0 blocking findings ends with rework 0 and one check pass, its advisories fixed in the same round or in the findings file.

### The merge phase spends output out of proportion to its calls (guide-colors retro)
- Location: `.claude/workflows/deliver-change.js`, the merge phase, and `.claude/agents/merger.md`
- Why: guide-colors merge took 26,423 output tokens for 11 calls and 4 CI-wait calls (9.1 percent of 290,842) on a 7-minute green CI; the last 10 feature rows range 4,992 to 98,694 merge output at 10 to 21 calls.
- Fix: a run green on its first CI pass keeps its merge phase under 10,000 output tokens; accepted over 5 consecutive runs.

### A passing check phase costs a full agent start (guide-colors retro)
- Location: `.claude/workflows/deliver-change.js`, the check phase, and `.claude/agents/checker.md`
- Why: guide-colors check took 30,277 output tokens for 5 calls over two passes with all 9 stages passing (10.4 percent of 290,842), though the stages are deterministic; the benchmark already records equal figures without an agent.
- Fix: record a check phase whose stages all pass without an agent's reasoning, or with a minimal start; accepted when such a phase records under 3,000 output tokens.
