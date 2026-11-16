# Tasks

## 1. Openers in the tokenizer

- [ ] 1.1 Give `Carat::Plugins::Ruby::Tokenizer` (`carat/plugins/ruby/tokenizer.rb`) the per-line `ends` and `opens` counts with the modifier, loop `do`, and endless `def` rules; prove with the opener table in `test/plugins_ruby.rb`

## 2. The structure check

- [ ] 2.1 Add `Carat::Plugins::Ruby::Structure` (`carat/plugins/ruby/structure.rb`) returning the row of the innermost opener left open; prove with the structure table in `test/plugins_ruby.rb` (a row per opener, modifiers, a closed file, literals)
- [ ] 2.2 Subscribe `Carat::Plugins::Ruby::Plugin` to `buffer_open`, `buffer_change`, and `mode_change` and place or clear the `error` sign; prove with `test/editor_ruby_structure.rb` (on open, waiting in insert mode, cleared after `<Esc>`, a non-Ruby file unmarked)

## 3. Docs and checks

- [ ] 3.1 Update `docs/codebase-map.md` (the new file and test), `docs/plugins.md`, and the README, `docs/architecture.md` unchanged as the proposal says; prove with `make docs-lint` and `make lint`
- [ ] 3.2 Confirm `lh-ruby` and `open-ruby` allocations with `make bench SCENARIOS="lh-ruby open-ruby"`, then run `make gates` and `make spec-validate`
