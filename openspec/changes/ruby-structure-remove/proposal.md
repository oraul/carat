# Proposal

## Why

The unclosed-opener sign that #147 added (`ruby-structure-check`) rescans the whole Ruby buffer when it opens and after each normal-mode change: it took a 100,000-line Ruby file's open from 22 to 116 ms, and the user asked for its removal. Highlighting does not need it, so the check goes and the plugin is a tokenizer again.

## What Changes

- Remove the `error` sign the `ruby` plugin placed on the innermost block opener no `end` closes, and with it the plugin's `buffer_open`, `buffer_change`, and `mode_change` events, its whole-buffer check, and its Ruby file name tables.
- Remove `Ruby::Structure` and the tokenizer's opener counting (the `opens`, `ends`, and loop state, the modifier and endless-definition checks), which nothing else reads; the tokens and the line states are unchanged.
- Remove the editor test of the sign and the structure rows of the plugin's unit test; the token and state rows stay byte-identical.
- Remove the two ruby-syntax requirements on the sign and the opener counting, and the README sentence describing the sign.
- **BREAKING** for users only in that the sign no longer shows; a language server's diagnostics still report unbalanced blocks.

Out of scope: any other highlighting change, the sign API of the plugin host (other plugins and tests use it), and the `Structure` highlight group, which is Neovim's group for `class` and `module` and stays.

Roadmap: outside the roadmap of `docs/architecture.md` section 12; a user-requested removal of a delivered plugin feature (Sprint 15 item 1 of the feature queue).

Minor assumptions: the plugin's manifest version stays `1.1.0`, since the plugin API and its tokenizer output are unchanged; the backlog entries the brief names all close with the removal, since each concerns only the removed check.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `ruby-syntax`: removes "An unclosed block opener is marked without a language server" and "Openers are counted as Ruby reads them".

## Impact

- Code: `carat/plugins/ruby/plugin.rb`, `carat/plugins/ruby/tokenizer.rb`; `carat/plugins/ruby/structure.rb` deleted.
- Tests: `test/editor_ruby_structure.rb` and its snapshot deleted, its lines in `test/runner/run_all.rb` removed; `test/plugins_ruby.rb` and its snapshot lose the structure rows.
- Performance: the `open-ruby` and `lh-ruby` scenarios no longer pay a whole-buffer pass on open.
- Docs: `docs/codebase-map.md` area 14, `docs/plugins.md` (the sentence on the ruby plugin's events).
- README.md: changed, the sentence on the sign is removed.
- docs/architecture.md: unchanged, it never described the sign or the check.
- CLAUDE.md: unchanged, no process change.
