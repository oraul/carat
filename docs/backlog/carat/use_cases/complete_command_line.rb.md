# Backlog: carat/use_cases/complete_command_line.rb

### The completion popup's float close is written twice
- Location: carat/use_cases/complete_command_line.rb `close` and carat/use_cases/close_cmdline_menu.rb `call`
- Why: both close the popup's float and zero its id; a change to how the popup closes must be made in two places.
- Fix: give CloseCmdlineMenu a keep-matches variant or move the float close into one private helper both reach, then let CompleteCommandLine call it on the cycle path.
- Also: carat/use_cases/close_cmdline_menu.rb
- Category: editor
- Added: 2026-11-21

### A command-name popup is not under the typed word
- Location: carat/use_cases/complete_command_line.rb `show`, carat/domain/float_window.rb `place` (MARGIN)
- Why: an editor-anchored float keeps one cell of margin, so for a word at the start of the line the popup's text starts at column 3 instead of column 1, under the colon's neighbour, unlike Neovim's pum.
- Fix: add a placement for the command line (an anchor or a margin flag on FloatSpec) that lets the box touch column 0, and align the text with the word's first cell.
- Also: carat/domain/float_window.rb
- Category: editor
- Added: 2026-11-21

### Tab cycling in the command-line menu depends on the popup being open (sprint-25 review quality)
- Location: `carat/use_cases/complete_command_line.rb:73`
- Why: `CmdlineMenu#showing?` (popup open) stands in for "menu active"; when `show` returns early (screen_rows under 5, screen_cols under 8, or `open_float` refusing) float_id stays 0, so the next `<Tab>` completes afresh from the inserted match instead of cycling: a user-visible bug on a short or narrow screen, found by the sprint-25 review in cmdline-completion.
- Fix: decide cycling on the menu's own state (a current match with a non-negative start, or an active flag), not on the popup; accepted when a test on a 4-row screen cycles through 3 matches with `<Tab>`.
- Category: bug

### The completion popup's column is an arithmetic puzzle (sprint-25 review quality)
- Location: `carat/use_cases/complete_command_line.rb:274`
- Why: `col = 1 + text_width(...) - 1 - PAD`: the prompt colon and the border cancel, which the reader must work out.
- Fix: write `text_width(...) - PAD` with a one-line comment naming the two terms; accepted when the popup frame rows are unchanged.
- Category: quality

### duplication: collect_themes repeats the prefix-filter loop of collect_names (166-178) at carat/use_cases/complete_command_line.rb:182 (sprint-26 sweep quality, note 20)

- Location: carat/use_cases/complete_command_line.rb:182
- Why: duplication: collect_themes repeats the prefix-filter loop of collect_names (166-178) line for line over another list
- Fix: one private collect_prefixed(names, typed) called with ExTable#full_names and Domain::Themes::NAMES
- Category: editor
- Added: 2026-11-22

### cleverness: col = 1 + text_width(...) - 1 - at carat/use_cases/complete_command_line.rb:305 (sprint-26 sweep quality, note 21)

- Location: carat/use_cases/complete_command_line.rb:305
- Why: cleverness: col = 1 + text_width(...) - 1 - PAD, the +1 and -1 cancel
- Fix: col = Domain::DisplayWidth.text_width(state.cmdline[0, name_start].to_s, 0) - Domain::FloatWindow::PAD
- Category: editor
- Added: 2026-11-22
