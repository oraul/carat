# Backlog: carat/domain/ex_range.rb

## Ex ranges resolve no arithmetic, pattern, or other mark

- Where: `Carat::Domain::ExRange.resolve` in `carat/domain/ex_range.rb`, which reads `%`, `.`, `$`, a number, `'<`, and `'>`; `ExGrammar.range_end` already keeps `+`, `-`, `;`, and any `'x` in the range.
- Why it matters: `:.,+3s`, `:/foo/s`, `:'a,'bs`, and a count before `:` (Vim's `.,.+N-1`) answer `Not implemented: range x`, and the visual marks are not moved by later edits, as Vim's marks are.
- Fix outline: resolve `+N` and `-N` after an address or alone, `;` by moving the cursor line to the first address before the second, and `/pat/` and `?pat?` through `Search.find` under a budget; read `'a` to `'z` from the marks change, which also moves the visual marks with the splice.
- Category: editor
- Added: 2026-11-04

## ExRange keeps a given member no caller reads

- Where: `ExRange` in `carat/domain/ex_range.rb:12`, whose `given` member is set on every path but read only by `test/domain_ex_range.rb`. Quality advisory at 76ad185.
- Why it matters: a dead member costs a slot per range and suggests a behavior that does not exist.
- Fix outline: drop `given` from `ExRange`, its map entry, and the test's columns, or use it where `buffer-global` needs to tell a default range from a given one. Queued in `substitute-structure`.
- Also: test/domain_ex_range.rb
- Category: editor
- Added: 2026-11-04

## spinel-rebump quality advisory at carat/domain/ex_range.rb:46

Tests beside every behavior change: the new `Utf8.boundary` calls in `ExRange` and `MarkdownText` (`carat/domain/markdown_text.rb:53` and `:277`) have no test row, so dropping one brings the `IndexError` back unseen on text that is not UTF-8. Fix outline: add a row each, an ex range with a 0x80 after a comma and a markdown body with a 0x80 after a newline and after a `](`.
- Also: carat/domain/markdown_text.rb
- Category: editor
- Added: 2026-11-14

## The Spinel boundary guards in ExRange and MarkdownText have no test

- Where: `carat/domain/ex_range.rb:46`, `carat/domain/markdown_text.rb:53` and `:277`. Sprint-3 quality review of `spinel-rebump`.
- Why it matters: under the pinned Spinel a `byteindex` from a continuation byte raises `IndexError` without the `Utf8.boundary` guard; `RpcFramer`, `TextLines`, `VimPattern`, `Paths`, and `read_file` each got a regression row, these three did not, so removing a guard passes the suite.
- Fix outline: rows in `test/domain_ex_range.rb` (a range such as `1,` then a continuation byte) and `test/domain_markdown_text.rb` (a continuation byte after a newline and inside a link target). Queue item `spinel-workarounds`.
- Also: carat/domain/markdown_text.rb, test/domain_ex_range.rb, test/domain_markdown_text.rb
- Category: editor
- Added: 2026-11-14

### A range alone past the last line gives E16
- Location: carat/domain/ex_range.rb:51
- Why: :99 on five lines is refused, but Neovim and docs/compatibility.md move to the last line, E16 only before a command. Folded into core-correctness-b.
- Fix: clamp the last address in ExecuteEx#go_to, with a row in test/editor_cmdline.rb.
- Also: docs/compatibility.md, test/editor_cmdline.rb
- Category: editor
- Added: 2026-11-17

### ExRange resolve answers E16 for an implicit offset Neovim reads (vim-line-commands-b quality)
- Location: carat/domain/ex_range.rb:151
- Why: resolve now answers E16 for a range piece Neovim reads as an implicit offset (`.5`, `$ 1`, `. 5`), where it answered Not implemented before, since unread? counts only + - ; / ? ' and bare digit runs; a behavior change without its test.
- Fix: treat an address base (. or $) followed by digits or blanks as unread too, and add a domain_ex_range row for `.5d`.
- Category: editor
- Added: 2026-11-18
