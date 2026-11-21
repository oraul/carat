# Backlog: carat/use_cases/ex/set_command_handler.rb

## :set handles only filetype, syntax, the search options, and cursorline

- Where: `Carat::UseCases::SetCommandHandler` in `carat/use_cases/ex/set_command_handler.rb`, which handles `filetype`, `syntax`, and the booleans `ignorecase`, `smartcase`, `hlsearch`, and `incsearch` (since `buffer-search`) and `cursorline` (`cul`, since `cursor-shapes`), answers `Not implemented: :set name` for the other options the editor already has and `E518` for the rest; no `:setlocal`, no `:filetype`.
- Why it matters: `:set number`, `:set ts=4`, `:set nowrap`, and the rest of Neovim's option commands are roadmap item 9, `options-and-config`.
- Fix outline: grow the handler into the option table that item brings (names, abbreviations, types, global or local), keeping the `filetype`, `syntax`, and search answers; add `:setlocal` and the `&`, `+=`, `-=` forms there, with `no`, `inv`, `!`, and `?` moved from the booleans to every boolean.
- Category: editor
- Added: 2026-11-05

## The boolean options of :set are three parallel switches with a silent default

- Where: `full_boolean`, `set_boolean`, and `on?` in `carat/use_cases/ex/set_command_handler.rb` (line 122 at `cursor-shapes`); `set_boolean` and `on?` fall through to `incsearch` in their `else`. Quality advisory of `cursor-shapes`.
- Why it matters: a fourth boolean option needs an edit in each of the three, and a missed branch silently reads or writes `incsearch`.
- Fix outline: one table of name, abbreviation, and `Options` member read by all three, or an explicit `incsearch` branch with no silent `else`.
- Category: editor
- Added: 2026-11-05

## :set jumptab answers E518 while :set breadcrumbs answers Not implemented

- Where: `carat/use_cases/ex/set_command_handler.rb:27`. Periodic quality advisory.
- Why it matters: `PENDING` copies `Options::KINDS` by hand and misses jumptab, indentguides, keyhints.delay, and layout.
- Fix outline: derive the names from `Options::KINDS` plus the abbreviations, with a row for `:set jumptab`. Backlog batches (config checks).
- Category: editor
- Added: 2026-11-10
