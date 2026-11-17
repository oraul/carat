### Planner and scout resolve the brief's locations twice (ci-trust-gaps retro)
- Location: `.claude/agents/planner.md`, `.claude/agents/scout.md`, `.claude/workflows/deliver-change.js` (the plan and scout phases)
- Why: ci-trust-gaps spent plan 28,293 plus scout 48,985 = 77,278 of 252,190 output tokens (30.6 percent) and 28 of 172 calls, the planner and scout disagreeing on one location (`deliver-change.js:614` against `:618`); tab-close-b 33.7 percent, check-parallel 29.8 percent.
- Fix: one of the two resolves locations and the other reuses its pack; accepted when the next three pipeline-lane rows hold plan plus scout under 20 percent of output tokens with no location re-corrected by the scout.

### The quality reviewer investigates findings it hands to security (ci-trust-gaps retro)
- Location: `.claude/agents/quality-reviewer.md`
- Why: in ci-trust-gaps quality note 1 (a replace ref past fsck, marked security's to judge) was the Medium (8) security then blocked on, the run's 1 rework round; reviews 50,343 of 252,190 output tokens (20.0 percent) and 27.3 percent of calls; quality first pass 77/143, the lowest gate.
- Fix: a finding the quality reviewer marks security's to judge is named, not investigated; accepted when reviews fall below 15 percent of output tokens on the next three pipeline rows with security never skipped.
