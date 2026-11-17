### The contributor returns work the quality review blocks on its first pass (plugin-lazy-activate retro 11)
- Location: `.claude/agents/contributor.md`, the contributor's self-check before it returns; `.claude/workflows/deliver-change.js`, the quality round.
- Why: quality passes first 85 of 153 runs against check 150/153 and security 147/153; plugin-lazy-activate had 2 blocking findings of two kinds (a test expectation edited against plugin-host spec.md:100 and :115 left in force; a new raise branch at plugin_syntax.rb:48 without its test), its rework round 104,027 output tokens, 30 percent of 343,926; lsp-container-b and vim-folds-a also quality:0 in the feature lane's last 10.
- Fix: make the contributor catch these two kinds before it returns, without adding a phase; accepted when status shows quality first passes at 8 or more of the next 10 feature runs and none of these two blocking kinds.

### A scout runs for an area the change barely edits (plugin-lazy-activate retro 12)
- Location: `.claude/workflows/deliver-change.js`, the scout plan from the areas start.
- Why: plugin-lazy-activate spent 57,113 output tokens and 40 calls on scouts (16.6 percent of 343,926 output, 16.5 percent of 242 calls) for 3 packs, one (build-and-ci) for 8 of 813 changed lines; scout shares tab-close-b 25 percent, tab-close 21 percent, secret-patterns 33.6 percent.
- Fix: skip or fold the scout of an area whose planned edit is a few lines; accepted when the scout share of output over the next 10 feature runs has a median at or under 12 percent with first.check and first.quality rates not lower.
