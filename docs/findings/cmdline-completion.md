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
