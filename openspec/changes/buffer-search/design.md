# Design

## Context

See `proposal.md` for why. What exists today (scout packs at 8c340cd, re-read on the branch): `/ ? n N` are bound to four reserved `search.*` actions that `MessageHandler` answers with "Not implemented"; no binding exists for `* # g* g#`. Motions are pure functions in `Domain::Motions` reached through `Move` and `Operate#motion_for`; the command grammar reads an action by its handler's kind and has no way to read a whole pattern. The command line is one string on `EditorState`, with no history and no prompt kind. `Registers#read("/")` answers nil. The four search options are validated in `Options::KINDS` but not stored. The frame presenter paints text, then tokens, then the selection, and a row is repainted only when its `PaintedRows` record differs.

Spinel's runtime `Regexp` (probed on the pinned compiler) matches without backtracking unless a pattern has a back reference, a look-around, or an atomic group; those run on a backtracking engine bounded by a step limit that raises `RegexpError`. Its cost is about the characters scanned times the pattern's size (a pattern of about 300 states took 1.3 s over a million characters; a counted repetition of a million states took 0.6 s to compile). A match on text that is not valid UTF-8 raises `ArgumentError`. `Regexp#match(text, pos)` takes and `MatchData#begin` and `#end` give character indices, which are Carat's columns; `^` and `\A` do not match at a later `pos`.

## Goals / Non-Goals

**Goals:** Neovim's search keys and their messages; the magic pattern basics; a pattern can never crash or hang the editor; no added allocation on a key that does not search, and no added work in a frame without a highlighted pattern.

**Non-Goals:** `:s`, `:g`, `:v` (next change); offsets; the `[1/5]` count; `'wrapscan'`; a match across lines; a `WarningMsg` group.

## Decisions

### Translate to Spinel's engine, never to a backtracking construct

`Domain::VimPattern.compile(source, ignorecase, smartcase)` walks the pattern once by code point (`Utf8.size_at` and `code_at`, so an illegal byte becomes U+FFFD and never reaches `Regexp.new`) and writes the engine's syntax: `\(` becomes the non-capturing `(?:`, `\<` and `\>` become `\b`, the class escapes become ASCII brackets (`\k` is Carat's keyword class, ASCII word characters and U+00C0 upward), every character the engine would read specially is escaped. Back references and look-around are refused with "Not implemented", so every compiled pattern runs on the engine that does not backtrack. Each token is normalized first by the magic level (`\v`, `\m`, `\M`, `\V`), so one translator serves all four. The result is a `SearchPattern` value (source, regexp or nil, size, error). Writing our own matcher was considered: it would give an exact step count but costs a regular expression engine in Ruby on the hot path; the engine Spinel ships is in C and the brief asks for it.

The compiled size is estimated during translation (an atom is 1, a counted repetition multiplies its operand by its largest count) and capped at 2,000; above it the pattern is refused with E363 before `Regexp.new` runs, which bounds compile time and memory and the per-character cost of matching.

### Charge a budget before the engine runs

`Domain::Search` matches line by line. Before each `Regexp#match` it charges the worst case, the line's length (the engine finds a code point position from the line start, so a line of many matches searched backward costs its length per match) plus the characters left on the line times the pattern's size, to a `SearchBudget`, and refunds only the scan it did not use; when the budget cannot pay, the search stops with "E363: search stopped, pattern too costly here". A search has 400 million units (about 1.5 s at the measured rate for the largest pattern, and 130 million characters for a small one); a frame's highlighting has 20 million and stops highlighting rows when spent, never the editor. `RegexpError` and `ArgumentError` from the engine are rescued and become the same stop. A line that is not valid UTF-8 is matched through a copy with U+FFFD for each illegal byte, built by `Utf8` so it has exactly the line's characters.

A timeout through `ClockPort` was considered: it would make the tests depend on time and the domain on a port; the budget is deterministic and needs neither.

### The grammar reads a pattern like it reads a character

A new handler kind `:search` (the actions `search.forward` and `search.backward`) makes the grammar keep the action and answer `:prompt` in normal, operator-pending, and visual modes, with the count, register, and operator kept. `HandleKey` calls `OpenSearchPrompt`, which records the prompt in `SearchPrompt` (direction, the mode to return to, the cursor and the window's top) and enters command-line mode. Enter (`ExecuteCommandLine`) and Escape (`CancelCommandLine`) put the mode and cursor back and close the prompt, Enter recording the text; after dispatching a command-line action `HandleKey` sees the prompt closed and either hands the text to the grammar, which completes the command with the pattern as its argument (`Command#char`), or resets it. The finished command is dispatched like any other: the search handler moves the cursor, or the operator's handler runs `Operate`. Because the pattern travels in the command, the dot command repeats `d/foo` with `foo`, as Vim does. Having `ExecuteCommandLine` dispatch the search itself was rejected: it would re-enter the dispatcher inside a dispatch.

`n N * # g* g#` are ordinary `:motion` actions. `FindMatch` resolves every search action to a `SearchHit` (target or none, message, error) and records the last pattern (`LastSearch`, the `/` register, the history); `JumpToMatch` moves the cursor for the handler, and `Operate#motion_for` turns a hit into an exclusive charwise `Motion`, adding the search names to its register-1 list.

### History

`Domain::History` keeps up to 50 entries, newest last, without duplicates, and the recall position with the prefix typed before the first recall. One instance serves `:` (written by `ExecuteCommandLine`) and one the search prompt (written at Enter and by `* # g* g#`). `RecallHistory` replaces the command line with the next older or newer entry that starts with the prefix.

### Highlighting

Two editor groups, `Search` and `IncSearch`, take ids 11 and 12; the syntax groups move to 13 to 42, which every theme row names symbolically. `LastSearch` holds the compiled last pattern, whether it is shown (false after `:noh`), the preview of the prompt (its pattern and the current match), and a stamp that grows whenever what is highlighted changes. The presenter asks it for the pattern to draw under the options; when none, it passes 0 into the painted-row record and does no other work, so a frame without search costs one comparison per row. Otherwise the record carries the stamp, rows repaint when it changes, and `paint_row` fills the `Search` group over each non-empty match in the visible columns, then `IncSearch` over the current preview match, before the selection.

### Options

`ignorecase`, `smartcase`, `hlsearch`, and `incsearch` become `Options` members with Neovim's defaults (off, off, on, on), set by the configuration and by `:set` with Vim's boolean forms; changing the case options recompiles the last pattern, and setting `hlsearch` shows the highlight again.

## Risks / Trade-offs

- `\<` and `\>` both become `\b`, so `\<` also matches at the end of a word when the next item is not a keyword character; `*` and `#` always put a keyword after it, where the two agree. Recorded in `docs/compatibility.md`.
- The budget charges the worst case, so a very large buffer searched with a large pattern can stop where Vim would finish; the limits allow 130 million characters for a plain word, and a backward search over a long non-ASCII line of many matches stops after about 400 million divided by the line's length matches.
- Renumbering the syntax ids changes no name a plugin sees (plugins ask by name), but any snapshot printing an id changes; the theme tests cover the ids.
- The wrap message is a plain message, since Carat has no `WarningMsg` group yet.
