# Tasks

## 1. Hints code

- [x] 1.1 `carat/domain/mode.rb`: add `Mode.grammar?`; `carat/use_cases/handle_key.rb` (`grammar_mode?`, `KeyHints#showing?` in `call`) and `show_key_hints.rb` read it; prove it in `test/editor_key_hints.rb` (the grammar modes table, and the existing insert-mode and close rows)
- [x] 1.2 `carat/use_cases/discovery/show_key_hints.rb`: take `hide_key_hints:` in place of `close_float:`, wired in `carat/adapters/editor_assembly.rb`; prove it in `test/adapters_assembly.rb` and `test/editor_key_hints.rb` (the next level shows after the delay)
- [x] 1.3 `carat/domain/options.rb`: build the default delay from `KEYHINTS_DELAY`; prove it in `test/editor_key_hints.rb` (the delay stays the default)

## 2. The panel and its names

- [x] 2.1 `show_key_hints.rb`: center the float at the bottom; prove it in `test/editor_key_hints.rb` (The hints are a centered bottom panel)
- [x] 2.2 `show_key_hints.rb`: name an unnamed prefix by its shared action segment or `group`; prove it in `test/editor_key_hints.rb` (A group without a name, A group of mixed actions)

## 3. Docs

- [x] 3.1 `README.md` (the key hints sentence), `docs/compatibility.md` (the key hints paragraph), `docs/codebase-map.md` (area 5, `show_key_hints.rb`); run `make docs-lint` and `make gates`
