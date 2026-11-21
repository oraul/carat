# Backlog: docs/compatibility.md

## The :noh row names a test that has no :noh case

- Where: the `:noh[lsearch]` row of `docs/compatibility.md` (line 262), and task 3.2 of the archived `buffer-search` change, which say `use_cases_ex` proves `:set` and `:noh`; `test/use_cases_ex.rb` has no `:noh` or search-option case. Quality advisory of `buffer-search` at 2b54295641e0 and again at a36858a2bc88.
- Why it matters: the compatibility table is how a reader finds the test of a command, and this one points to a file that does not test it (`editor_search` does).
- Fix outline: drop `use_cases_ex` from the row, or add the `:noh` and search-option cases to `test/use_cases_ex.rb`. Queued in `search-tidy`.
- Also: test/use_cases_ex.rb
- Category: design
- Added: 2026-11-04

## The float behavior of the close and focus commands has no compatibility row

- Where: `docs/compatibility.md`, for `:q`, `:close`, Ctrl-W c, the Ctrl-W focus commands, and normal-mode Esc in a float, at `floating-windows`. Quality advisory of `floating-windows`.
- Why it matters: in a float these close or leave only the float, and Esc closing floats is not Neovim's behavior, but no row records either, so the difference is invisible to a reader of the table.
- Fix outline: add rows naming `test/editor_floats.rb` for each, marking Esc as a difference from Neovim.
- Also: test/editor_floats.rb
- Category: design
- Added: 2026-11-07

## The diagnostics display is missing from the compatibility table and the architecture

- Where: the `:LspStart` row of `docs/compatibility.md` (line 278 at fb09c6b) and `docs/architecture.md` (line 260). Periodic quality at fb09c6b.
- Why it matters: the row omits that a start after a crash clears the drawn diagnostics (the language-server spec and the `editor_lsp` test 'diagnostics after a crash and a start' require it); no row describes the diagnostic signs over a plugin's sign or the cursor line's message in normal mode, though the `diagnostics-display` pull request says the table documents the display; the architecture still says the gateway returns `Diagnostic` values where `diagnostics(path)` returns a `DiagnosticList`.
- Fix outline: add the clearing to the `:LspStart` row, rows for the signs and the message row with their tests, and name `DiagnosticList` at the architecture line. Queued in `diagnostics-tidy`.
- Also: docs/architecture.md
- Category: design
- Added: 2026-11-07

## The mouse is not supported

- Where: the terminal driver and the key decoder; roadmap UI item `mouse`, moved here from `docs/queue.md` by the user's decision at `breadcrumbs`.
- Why it matters: not needed yet; carat never enables mouse reporting, so leaving it out breaks nothing. When it is done, three known risks: Shift-drag must still select text in the terminal, the reporting mode must be restored on every exit path (quit, crash, suspend, a raising plugin), and mouse sequences must be decoded so they never reach the keymap as typed keys.
- Fix outline: clicks, drags, and the wheel acting on windows, bars, and floats as in Neovim, each with a `docs/compatibility.md` row, with a case per exit path restoring the mode, a decoder case that no mouse sequence reaches the keymap, and a key costing nothing more. Not queued until the user asks.
- Category: design
- Added: 2026-11-09

## The docs deny or omit the winbar

- Where: `docs/compatibility.md` line 441 (Bars says no winbar, against Breadcrumbs at line 518); `docs/architecture.md` line 257 (the FramePresenter bullet omits the winbar row and its painter), at 7711421. Periodic quality. Queue items `docs-index` and `architecture-drift`.
- Why it matters: two documents contradict the delivered feature.
- Fix outline: drop the denial or point to Breadcrumbs; name the winbar and `Winbar` in the bullet.
- Also: docs/architecture.md
- Category: design
- Added: 2026-11-09

## The finder's normal-mode Ctrl-P differs from Neovim unsaid

- Where: the File finder section of `docs/compatibility.md` (line 493). Quality review of `file-finder`.
- Why it matters: normal-mode `<C-p>` moves the cursor up a line in Neovim; the finder takes it without saying so.
- Fix outline: note the difference in the section, removable with `keymap.normal <C-p> none`.
- Category: design
- Added: 2026-11-10

## The indent-guides docs claim an untested start screen and reword untouched sentences

- Where, at 6cb3c55: the Windows row of `docs/compatibility.md` line 537, which credits `adapters_indent_guides` with the start screen showing no guide though no case draws the start screen; `docs/architecture.md` lines 113 and 257, which reword sentences the change does not touch (the Nerd Font glyph clause, reading the state, the two preallocated frames). Quality advisories in `indent-guides`.
- Why it matters: a compatibility row naming a test that does not prove it hides a gap, and rewording unrelated sentences widens a change's scope and its review.
- Fix outline: add a start-screen case to the guides table or drop the start screen from the row's claim; restore the untouched wording and keep only the additions that name `indentguides`, `IndentGuides`, and the guides in the row record.
- Also: docs/architecture.md
- Category: design
- Added: 2026-11-10

### Quality: the winbar row of the compatibility table names the old separator, docs/compatibility.md:587

- Why: docs currency; the winbar row still says the symbols are joined by ` > `, while the winbar now joins them with ` › `.
- Fix: say ` › `, and ` > ` under `option.icons ascii`.
- Category: design
- Added: 2026-11-14

### The core Branch slot row of docs/compatibility.md contradicts the git_signs segment

- Location: carat/domain/status_slots.rb:18, carat/adapters/status_bar.rb:164 and :241, docs/compatibility.md:466 and :468 (sprint-9 review, quality); queued in `ui-code-tidy` beside "## The status bar's branch slot has no writer".
- Why it matters: only tests fill the core branch slot while git_signs draws the branch as its own segment at the same priority 40, yet the compatibility row says the core slot shows it.
- Fix outline: remove the slot from StatusSlots and StatusBar and fold the row into the git_signs row, or have the plugin fill the core slot.
- Also: carat/domain/status_slots.rb, carat/adapters/status_bar.rb
- Category: design
- Added: 2026-11-16

### vim-line-commands-b's quality advisories reached main unrecorded
- Location: `docs/compatibility.md:332` (the Substitute section's opening sentence pasted inside itself), `carat/domain/ex_range.rb:151` (`.5`, `$ 1`, `. 5` answer E16 where Neovim reads an implicit offset, untested), `carat/domain/ex_range.rb:101` (resolve re-reads the error text against UNREAD), `docs/codebase-map.md:128` (Messages entry lacks E477 and REPORT; RegisterCount lacks parse_count).
- Why: the package step fixed 2, the push gate refused, it reverted them (653eefe) and appended 1 of 4 to docs/findings (vim-line-commands-b retro note 5).
- Fix: rewrite the sentence as one; treat an address base followed by digits or blanks as unread, with a `domain_ex_range` row for `.5d`; call `unread?` directly; name the 3 symbols in the map. Skip any part already folded from the vim-line-commands-b findings file.
- Also: carat/domain/ex_range.rb, docs/codebase-map.md
- Category: design
- Added: 2026-11-18

### The finder's <C-t> row leaves out the lone-tree case
- Location: docs/compatibility.md:528
- Why: the explorer's row (line 508) and the file-finder spec state that with no file window the tab open opens as <CR> does, but the finder's <C-t> row omits it, so the table under-describes the behavior
- Fix: append "and with no file window as <CR> opens" to the row
- Category: design
- Added: 2026-11-18

### The :p row gives its bang refusal as a bare E477
- Location: docs/compatibility.md:1
- Why: the :p row names its bang refusal as a bare E477 while its other errors and the :normal row give the full text.
- Fix: write E477: No ! allowed.
- Category: design
- Added: 2026-11-18

### The compatibility row misstates Neovim's sign column width

- Location: docs/compatibility.md:541
- Why: it says Neovim draws signcolumn=yes:1 one cell where its default auto takes two, but Neovim reserves two cells per sign column for both yes:1 and auto (auto:1), as the proposal itself says.
- Fix: write that the column is one cell where Neovim's sign column (yes:1 or the default auto) takes two.
- Category: design
- Added: 2026-11-19
