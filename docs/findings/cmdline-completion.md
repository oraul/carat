### The completion popup's float close is written twice
- Location: carat/use_cases/complete_command_line.rb `close` and carat/use_cases/close_cmdline_menu.rb `call`
- Why: both close the popup's float and zero its id; a change to how the popup closes must be made in two places.
- Fix: give CloseCmdlineMenu a keep-matches variant or move the float close into one private helper both reach, then let CompleteCommandLine call it on the cycle path.

### A command-name popup is not under the typed word
- Location: carat/use_cases/complete_command_line.rb `show`, carat/domain/float_window.rb `place` (MARGIN)
- Why: an editor-anchored float keeps one cell of margin, so for a word at the start of the line the popup's text starts at column 3 instead of column 1, under the colon's neighbour, unlike Neovim's pum.
- Fix: add a placement for the command line (an anchor or a margin flag on FloatSpec) that lets the box touch column 0, and align the text with the word's first cell.

### The command-line popup's allocation budget is measured, not gated
- Location: Makefile `bench-budget`, bench/keys.rb `cmdline-tab`
- Why: `bench-budget` fails only on `lh`; the popup scenario measured 79.5 objects per key, under the budget of 100, but a later change could raise it unnoticed.
- Fix: add `sh bench/run.sh --budget cmdline-tab $(ALLOC_BUDGET)` to `bench-budget`, with the CLAUDE.md line the Makefile rule asks for.
### An allocation regression is found only at the bench phase, after the check passed

- Location: the contributor's self-check and the check's stages before the bench phase (`make metrics-compare`, `.claude/workflows/deliver-change.js` bench phase); cmdline-editing note 3.
- Why: cmdline-editing first.bench=0, allocs.grep 774.4 to 779.9 blocking at 065185360ef4 after the check passed there; the rework round took output from 299,373 to 406,940 (107,567, 22 percent of 481,005) through implement, check, security, and bench again; the contributor ran the metrics stage without comparing; picker-styles-b also had bench:0 with rework 3; bench first pass 234/236.
- Fix: an allocation increase over main's recorded figures in any scenario fails before the bench phase; accepted when first.bench stays 1 and no rework round has an allocation cause across the next 10 runs.

### Feature scouts cost about a quarter of a run's tool calls (cmdline-editing evidence, near-same as the `scout-prune` pool item of docs/queue-backlog.md, to be merged into it)

- Location: the scout and areas phases of `.claude/workflows/deliver-change.js`; cmdline-editing note 4.
- Why: scout 51 of 219 calls (23.3 percent) and 72,557 of 481,005 output (15.1 percent) plus areas 5 calls, 5,750 output, for 3 packs, none reused; feature scouts 28 to 45 calls in the last 5; implement still 73 to 92 calls against 46 in the no-scout runs contributor-tier-high and backlog-records-rule.
- Fix: as `scout-prune`; accepted when across the next 10 feature runs scout plus areas stays under 10 percent of tool calls (or is merged away) while implement calls do not rise above the no-scout runs' level.

### Medium-estimate feature runs overrun their 1.2M budget (cmdline-editing evidence, near-same, to be merged into that entry)

- Location: `docs/goals.md` The rubric (sizes), `sh tools/run_state.sh budget`, and the mid-run overrun note at each check pass; cmdline-editing notes 5, 6, 1, 2.
- Why: 12 of 12 medium rows in the last 10 of each lane exceed 1,200,000 total tokens (feature 1,226,138 to 2,192,549; backlog 1,362,861 to 2,119,140); cmdline-editing 1,418,893 total in 131 minutes wrote 2 overrun notes (299,373 and 406,940 output against 200,000) and continued unchanged both times.
- Fix: as that entry; accepted when a majority of the next 10 medium rows end under their size's budget, or no mid-run overrun note is written that no phase acts on.
