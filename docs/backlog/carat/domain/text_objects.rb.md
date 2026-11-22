# Backlog: carat/domain/text_objects.rb

## The local cls is the abbreviation the naming rule forbids

- Where: the local `cls` in `carat/domain/text_objects.rb` (line 86 at 3895e21) and the parameter `cls` of `Runs#add` (`carat/domain/runs.rb:18`). Periodic quality at 0b17324. Raised again at ce6abdb (periodic quality), queue item `editing-counts`. Raised again at be4b63a (owner `editing-counts`).
- Why it matters: `CLAUDE.md` names `cls` as the counterexample of its naming rule (`char_class`, not `cls`).
- Fix outline: rename both to `char_class`. Queued as a fold of `search-structure`.
- Also: carat/domain/runs.rb, CLAUDE.md
- Category: editor
- Added: 2026-11-04

## ci" on an empty string fails

- Where: the inner quote object in `carat/domain/text_objects.rb` line 356 at 38628bb (periodic quality). In the backlog items of the queue.
- Why it matters: on `""` Neovim enters insert between the quotes; carat fails, and `docs/compatibility.md` lists no difference.
- Fix outline: return the empty range after the opening quote, with an `editor_text_objects` row.
- Raised again at 6a0db20 (periodic quality, note 24): also `ci(` on `()` at `carat/domain/text_objects.rb:307`. Owner: queue item `editing-counts`.
- Also: docs/compatibility.md
- Category: editor
- Added: 2026-11-09

## aw and aW take the punctuation after a word

- Where: `carat/domain/text_objects.rb` line 110 at 3895e21. Periodic quality. Queue item `editing-counts`.
- Why it matters: `daw` on `foo` in `foo.bar` or `foo(x)` deletes `foo.` or `foo(`, unlike Neovim and the `docs/compatibility.md` row; no row covers a word before punctuation.
- Fix outline: take the next run only when it is blank, else the blanks before, as the quote and count paths do; `daw` and `yaw` rows before punctuation in `test/editor_text_objects.rb`.
- Also: docs/compatibility.md, test/editor_text_objects.rb
- Category: editor
- Added: 2026-11-09

## text_objects reaches Walker without requiring it

- Where: `carat/domain/text_objects.rb:252` and `:7`. Periodic quality.
- Why it matters: the require rule; it works only through `motions.rb`.
- Fix outline: require walker beside runs. Queue item `editing-counts`.
- Category: editor
- Added: 2026-11-10

### A counted aw starting on blanks takes the wrong span
- Location: carat/domain/text_objects.rb:116 (count loop 121-129)
- Why: 2aw on "  foo bar baz" takes blanks, foo, and the next blank instead of Vim's blanks, foo, blank, bar. Folded into core-correctness-b.
- Fix: step (blank, word) pairs when the cursor started on a blank, with a d2aw-from-blanks row in test/editor_text_objects.rb.
- Also: test/editor_text_objects.rb
- Category: editor
- Added: 2026-11-17

### text_objects.rb names a local cls

- Location: carat/domain/text_objects.rb:86 (sweep, quality).
- Why: cls is the abbreviation the CLAUDE.md naming rule forbids.
- Fix outline: rename it char_class.
- Also: CLAUDE.md
- Category: editor
- Added: 2026-11-17

### The cls abbreviation is still used (sprint-18 sweep quality)
- Location: `carat/domain/text_objects.rb:86`, `carat/domain/runs.rb:21`.
- Why it matters: CLAUDE.md names `cls` as the wrong form.
- Fix outline: rename to `char_class`.
- Also: carat/domain/runs.rb, CLAUDE.md
- Category: editor
- Added: 2026-11-18

### And carat/domain/text_objects.rb (sprint-20 sweep quality, runs.rb:18)

- Location: `carat/domain/runs.rb:18`
- Why: and carat/domain/text_objects.rb:86 name a character class cls, which the CLAUDE.md naming rule gives as its example of an unclear abbreviation (char_class, not cls)
- Fix: rename to char_class
- Also: carat/domain/runs.rb, CLAUDE.md
- Category: editor
- Added: 2026-11-19

### carat/domain/text_objects.rb:86: naming rule (no unclear abbreviations, CLAUDE.md names char_class, not (sprint-22 sweep quality)

- Location: `carat/domain/text_objects.rb:86`
- Why: naming rule (no unclear abbreviations, CLAUDE.md names char_class, not cls): the local cls, and the parameter cls of Runs#add (carat/domain/runs.rb:18)
- Fix: rename to char_class
- Also: CLAUDE.md, carat/domain/runs.rb
- Category: editor
- Added: 2026-11-20

### ci" on empty quotes fails where Neovim enters insert (sprint-24 sweep quality)

- Location: `carat/domain/text_objects.rb:356`
- Why: `i"` on `""` returns nil, so `ci"` fails instead of entering insert mode between the quotes.
- Fix: return the empty range at `q1 + 1`, with a row in `test/editor_text_objects.rb`.
- Also: test/editor_text_objects.rb
- Category: editor
- Added: 2026-11-21

### Unclear abbreviations cls, prev_len, and e at carat/domain/text_objects.rb:89 (sprint-28 sweep quality, notes 8, 28, 38)

- Location: carat/domain/text_objects.rb:89; carat/domain/runs.rb:18; carat/use_cases/erase_character.rb:43; carat/use_cases/plugins/plugin_registry.rb:311 (about 69 uses), plugin_syntax.rb:47
- Why: CLAUDE.md names `cls` as its example of an unclear abbreviation.
- Fix: char_class, previous_length, entry.
- Also: carat/domain/runs.rb, carat/use_cases/erase_character.rb, carat/use_cases/plugins/plugin_registry.rb, CLAUDE.md
- Category: editor
- Added: 2026-11-22
