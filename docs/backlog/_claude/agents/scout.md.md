# Backlog: .claude/agents/scout.md

### Scouting stays the costliest phase in tool calls (vim-folds-b retro 6)
- Location: `.claude/agents/scout.md`, `.claude/workflows/deliver-change.js` (scoutTargets)
- Why: 3 fresh packs at 37e72e3 took 44 of vim-folds-b's 139 calls (31.7 percent) and 62,465 output tokens (16.2 percent), the most scout calls in the last ten feature rows (11 to 40), while the packs held Designs 0, Rules 0, Bench 0 against Gaps 7 for 8 entry points and the contributor needed 34 implement calls.
- Fix: no empty pack section for a map area, fewer calls per pack; accepted when over the next 5 feature runs the scout phase stays under 20 percent of the run's tool calls with no rise in implement calls or quality first-pass failures (89/159 now).
- Also: .claude/workflows/deliver-change.js
- Category: pipeline
- Added: 2026-11-18
