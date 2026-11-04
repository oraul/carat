## Why

Carat has no Neovim search: `/`, `?`, `n`, and `N` answer "Not implemented", `*` and `#` are unbound, and the `/` register, `hlsearch`, `incsearch`, `ignorecase`, and `smartcase` are accepted but do nothing. Search is the first half of roadmap item 6, `search-and-substitute` (`docs/architecture.md` section 12); the planner split the item by the size rule, so this change delivers search and the next feature change delivers `:s`, `:g`, and `:v`.

## What Changes

- `/` and `?` open a search prompt on the command line; Enter searches forward or backward for the typed pattern, an empty pattern reuses the last one, and Escape or Backspace on an empty prompt returns to the mode it came from.
- `n` and `N` repeat the last search in its direction or the opposite one; `*`, `#`, `g*`, and `g#` search for the keyword under or after the cursor, whole word or not.
- Every search takes a count, works as an exclusive motion under an operator (`d/foo<CR>`, `cn`, `y*`) and in the visual modes, wraps around the buffer with "search hit BOTTOM, continuing at TOP" or "search hit TOP, continuing at BOTTOM", and reports `E486: Pattern not found: pat`, `E35: No previous regular expression`, and `E348: No string under cursor`.
- Vim's magic pattern basics are translated to the regular expression engine Spinel bundles: literal text, `.`, `*`, `\+`, `\=`, `\?`, `\{n,m}` and its lazy form, `^`, `$`, `[...]` collections with ranges and `[:class:]`, `\(\)`, `\%(\)`, `\|`, `\<`, `\>`, the class escapes `\s \S \d \D \w \W \a \A \l \L \u \U \x \X \h \H \k`, `\c`, `\C`, and the `\v`, `\m`, `\M`, `\V` modes. Back references, look-around, `\z`, `\%` items other than `\%(`, `\_`, and matches across lines answer "Not implemented"; Vim's error numbers are kept for malformed patterns (`E54`, `E55`, `E61`, `E62`, `E64`, `E554`).
- A pattern is untrusted input: it is translated only into constructs the engine matches without backtracking, its compiled size is capped (`E363`), every search and every highlighted frame has a work budget charged per line before the engine runs, a line that is not valid UTF-8 is matched through a copy with U+FFFD for each illegal byte, and an engine error becomes a message. No pattern can crash or hang the editor.
- The last pattern is kept in the read-only `/` register, which `"/p` puts and `:registers` lists.
- The command line keeps a history for `:` and one for search; `<Up>` and `<Down>` recall older and newer entries that start with the typed text.
- `hlsearch` highlights every match of the last pattern in the visible rows in the theme group `Search`; `incsearch` moves the cursor to the first match while the pattern is typed and draws it in `IncSearch`; `:noh[lsearch]` hides the highlight until the next search.
- `ignorecase` and `smartcase` decide whether a pattern matches case; `\c` and `\C` override them; `*` and `#` ignore `smartcase`, as in Vim.
- `ignorecase`, `smartcase`, `hlsearch`, and `incsearch` become stored options, set by the configuration and by `:set name`, `:set noname`, `:set invname`, `:set name!`, and `:set name?`.
- The four reserved `search.*` actions are implemented, so the Reserved list of `docs/actions.md` is empty; `MessageHandler` keeps only the quit hint and the register prefix.
- A benchmark scenario `n` measures repeated `n` on a buffer of 100,000 lines; keys that do not search allocate what they did before.

## Capabilities

### New Capabilities

- `search`: pattern search in a buffer: the search prompt, the repeat and word searches, counts, wrapping, operator and visual use, the supported pattern language and its errors, case options, the bounds on untrusted patterns, the history, and the highlighting of matches.

### Modified Capabilities

- `registers`: the `/` register holds the last search pattern instead of nothing.
- `color-themes`: the editor's own groups gain `Search` and `IncSearch`.
- `command-line-mode`: the command line keeps a history recalled with `<Up>` and `<Down>`.
- `normal-mode`: the requirement that `/` reports "Not implemented" is removed, since no action the default configuration binds is unimplemented any more.

## Impact

- Domain: new `VimPattern` (translation), `SearchPattern`, `Search` (matching under a budget), `SearchBudget`, `SearchHit`, `LastSearch`, `SearchPrompt`, and `History`; `CommandGrammar` gains the `:search` kind, which reads a pattern; `Options` gains four members; `Registers` gains `search`; `Highlight` gains two editor groups, renumbering the syntax ids.
- Use cases: new `FindMatch`, `JumpToMatch`, `OpenSearchPrompt`, `PreviewSearch`, `RecallHistory`, `SearchHandler`, and `NohlsearchCommandHandler`; `HandleKey`, `Operate`, the command-line use cases, `SetCommandHandler`, and `MessageHandler` change.
- Adapters: `FramePresenter` and `PaintedRows` paint the search groups; `EditorAssembly` wires the new records and use cases.
- Configuration: bindings in the normal, operator-pending, visual, and cmdline maps of `config/default.caratrc`, regenerated with `make gen-config`.
- Docs: `docs/compatibility.md`, `docs/actions.md`, `docs/spinel-notes.md`, `docs/codebase-map.md`, `docs/backlog.md`, `README.md`.
- Out of scope: `:s`, `:g`, `:v`, and `~` with a substitute string (the next change), search offsets (`/foo/e`), the search count display `[1/5]`, `'wrapscan'` off, `CurSearch`, `<C-r>` and the other command-line editing keys, and a `WarningMsg` group (the wrap message is drawn as a plain message).
