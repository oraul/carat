### No case for a merged sha git cannot resolve
- Location: tools/tools_test.sh:311
- Why: the proposal counts a reported merged sha git cannot resolve (a mistyped hash) as a disagreement, but only a resolvable pushed head is tested, so a regression in that path would pass tools-test.
- Fix: add an expect running phase CHANGE merge merged with a hex value naming no commit and checking that the squash commit is recorded and the merge-disagreement note is written.

### The contributor's extras ship without their tests (T1 efficiency)
- Location: `.claude/agents/contributor.md`, its self-check step
- Why: motions-search-tidy first.quality 0 on :g and :v reading ~ through compile_search (`carat/use_cases/search/global_command.rb:65`, an extra the proposal named), the round adding 122,352 output tokens (30 percent of 407,893); 21 of 142 recorded quality-blocking notes read behavior change without its test; quality first pass 79/145.
- Fix: the self-check holds each extra the proposal names to its test like a brief entry; accepted when over the next 10 runs no quality-blocking note reads behavior change without its test on code the proposal lists as an extra.

### Passing check starts vary from 1,598 to 150,693 output tokens (T1 efficiency)
- Location: `.claude/agents/checker.md`
- Why: motions-search-tidy check 57,058 output tokens and 10 calls for two passing checks (14.0 percent of 407,893 output on 5.3 percent of 188 calls); 6 of the last 21 rows over 35,000 against a median of about 6,700; check first pass 143/145, no decision changed.
- Fix: a passing check reports from its stage logs without further reading; accepted when over the next 5 runs every passing check start costs under 12,000 output tokens.

### Scouts run on a one-area removal the plan already maps (T1 efficiency)
- Location: `.claude/workflows/deliver-change.js`, the scout phase
- Why: ruby-structure-remove scout 33,374 output tokens and 17 calls, 24.6 percent of 135,491 output and 14.4 percent of 118 calls with areas=1, while the plan named every line range; scout share tab-close-c 13.2, markdown-reading-d 11.0, lsp-container-c 16.8, vim-line-commands-a 21.9, bar-colors 28.3 percent.
- Fix: skip or shrink the scout when the plan already names every file and range; accepted when the next one-area removal or revert runs with no scout start (or under 10,000 scout output tokens) and keeps first.check, first.quality, and first.security at 1.
