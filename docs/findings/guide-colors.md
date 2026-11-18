### Advisory-only fix rounds cost a full review round (sprint-17-records retro)
- Location: `.claude/workflows/deliver-change.js`, the rework loop after the reviews
- Why: every review of sprint-17-records reported 0 blocking, yet 2 of 3 rework rounds fixed advisories only (5, then 2), each rerunning check, security, and quality; reviews took 30,387 of 72,515 output tokens (41.9 percent) and 40 of 113 tool calls, against 11,232 of 64,769 (17.3 percent) at rework 0 in sprint-16-records. A near-duplicate of the `advisory-findings-auto` entry; merge into it at grooming.
- Fix: a run whose reviews report no blocking finding uses at most one fix round; accepted when its reviews stay under 25 percent of output tokens.

### Groom leaves references to the findings files it removes (sprint-17-records retro)
- Location: `tools/run_state.sh` groom and its fold of `docs/findings/`, `tools/docs_lint.sh` path check
- Why: docs-lint refused 3 backticked paths to removed findings files that needed hand edits, as in earlier records changes, and missed a bare file name (`docs/queue-feature.md:44` naming vim-folds-b.md:36), 1 of 5 first-pass advisories that opened rework round 1 (rework 2 in sprint-17-records).
- Fix: groom rewrites or refuses references to the files it removes, bare names included; accepted when the next records change needs no hand edit for a removed findings file and no review reports one.
