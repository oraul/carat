# Design

## Context

The ruby plugin tokenizes one line at a time for `HighlightView`, which only tokenizes the rows it draws, so the end state of the last line of a file is never known there; the packed `LineState` already uses all 58 bits for heredocs and string frames. A missing `end` is only known at the end of the file, so marking the opener needs a pass over the whole buffer. The plugin API already gives a plugin `read_buffer`, `place_sign`, and `clear_signs`, and the events `buffer_open`, `buffer_change`, and `mode_change`.

## Goals / Non-Goals

**Goals:**
- Find the innermost opener left open with the tokenizer's own knowledge of code, strings, comments, heredocs, labels, and dots.
- Leave the highlight path's allocations unchanged: the tokenizer gains integer counts only.
- Never rescan a buffer per keystroke in insert mode.

**Non-Goals:**
- Guessing the missing `end` by indentation, or marking an extra `end`.
- A new plugin API request or a change to `LineState`.

## Decisions

- Per-line counts in the tokenizer. Within one line, an opener followed by an `end` cancels, so any line reduces to some `end`s that close earlier openers followed by some openers it leaves open. `Tokenizer#call` keeps two integers, `ends` and `opens`, reset per line; an opener adds to `opens`, an `end` takes one from `opens` or else adds to `ends`. Alternative: storing an opener depth in `LineState` and reading the host's cached states; rejected because no bit is free and the cache never reaches the end of the file.
- Opener rules in `word`, where the keyword is known: a block `if`, `unless`, `while`, `until` is one met while an operand is expected (`@operand` false), not right after `}`, and not right after a jump keyword (`return`, `break`, `next`, `redo`, `retry`, `yield`, `super`); a `while`, `until`, or `for` sets a per-line flag that its `do` consumes; `def` is an opener unless the name (and its parenthesized parameters on the line) is followed by `=`. These checks run only when such a keyword is met.
- `Structure` (`carat/plugins/ruby/structure.rb`) owns a tokenizer whose ids are all -1, so it emits no token, runs it over the lines from state 0, and keeps a stack of opener rows: each line pops `ends` rows (never below empty) and pushes its row `opens` times. It returns the top row, -1 for none. Alternative: scanning the host's tokens; rejected because tokens carry code-point columns and lose the operand state.
- The plugin subscribes to `buffer_open`, `buffer_change`, and `mode_change`. It tracks whether the mode is insert, replace, or completion; a change in those modes only remembers the buffer, checked when the mode ends; otherwise it reads the buffer, runs `Structure`, clears its signs, and places `error` on the row found. Buffers whose event path is not a Ruby file name are skipped before reading.

## Risks / Trade-offs

- [A whole-buffer pass on open and on each normal-mode change of a large file] → the pass is one tokenizer run without token output; it does not run on cursor moves, so `lh-ruby` and `open-ruby` allocations per key hold, and the `open-ruby` open time is reported.
- [Heuristic modifiers: an `if` after a line ending in a value with a continuation] → such code is rare; the mark only shows a sign and changes no text.
- [Plain matching marks an outer opener when an inner `end` is missing] → the innermost opener left open is marked; indentation-guided matching is left out of scope.
