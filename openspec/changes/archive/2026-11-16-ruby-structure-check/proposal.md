# Proposal

## Why

An unclosed `def`, `class`, `module`, `do`, or `if` in a Ruby buffer shows nothing until a language server answers, and nothing at all without one, so a missing `end` is found only when the file is run. The ruby plugin already tokenizes Ruby and knows which words are keywords in code, so it can find the opener left open without a server. This is sprint 9's item `ruby-structure-check`, a T2 user request.

## What Changes

- Mark an unclosed block opener in a Ruby buffer with the `error` sign on its row: the ruby plugin checks the buffer when it opens, after every change made outside insert mode, and when insert mode ends, and moves or clears its sign as the result changes.
- Count as openers `def` (not an endless `def name = value`), `class`, `module`, `begin`, `case`, `for`, `do` (not the `do` of a `while`, `until`, or `for` on its line), and `if`, `unless`, `while`, `until` that start an expression (not the modifier forms after a value or after `return`, `break`, `next`, `redo`, `retry`, `yield`, or `super`); `end` closes the innermost open one. Words in strings, comments, heredocs, symbols, labels, and after a dot are not counted, since the tokenizer already skips them.
- Give the tokenizer two counts per line, the `end`s that close openers of earlier lines and the openers the line leaves open, read by a new `Structure` class that runs a tokenizer of its own over the lines and returns the row of the innermost opener left open.
- Document the check in the README, `docs/plugins.md`, and the map.

Out of scope: an extra `end` with no opener (no mark); marking by indentation which `end` is missing (the innermost opener left open by plain matching is marked); a message or underline beside the sign; checking a buffer whose filetype was set by `:set filetype` without a Ruby file name; any change to the language server's diagnostics.

Roadmap: outside the roadmap order of `docs/architecture.md` section 12; it extends the delivered `ruby` plugin (section 9.1 tokenizers) at the user's request.

Assumptions: a buffer is Ruby when its file name is one `Domain::Filetype` maps to ruby (`.rb`, `.rake`, `.gemspec`, `.ru`, `Gemfile`, `Rakefile`), the plugin being unable to name a domain constant; while typing in insert, replace, or completion mode the sign waits for the mode to end, so a keystroke never rescans the buffer; when several openers are left open the innermost (the last opened) is marked, as that is where the typing usually is; a whole-buffer check on open costs one tokenizer pass over the file, which the `open-ruby` timing shows.

## Capabilities

### New Capabilities

### Modified Capabilities

- `ruby-syntax`: an unclosed block opener is marked with a sign without a language server.

## Impact

`carat/plugins/ruby/tokenizer.rb` (the two counts, the modifier and endless-def tests), a new `carat/plugins/ruby/structure.rb`, `carat/plugins/ruby/plugin.rb` (events `buffer_open`, `buffer_change`, `mode_change`; the sign); tests in `test/plugins_ruby.rb` (a table per opener) and a new `test/editor_ruby_structure.rb` (the sign in the editor). No dependency and no plugin API request is added; the ruby plugin's version goes to 1.1.0. Moving the cursor never runs the check, so `lh-ruby` and `open-ruby` allocations per key hold.

- README.md: changed, the ruby plugin's structure sign.
- docs/architecture.md: unchanged, the layers, ports, and plugin API hold as they are; the check lives inside the existing `ruby` plugin and uses only requests it already has.
