# Tasks

## 1. Remove the sign from the ruby plugin

- [x] 1.1 Remove the events, `on_event`, `deactivate`, the host reference, `check`, `ruby_path?`, `TYPING`, `EXTENSIONS`, and `NAMES` from `carat/plugins/ruby/plugin.rb`, and its doc comment's description of the check; delete `test/editor_ruby_structure.rb`, its snapshot, and its two lines in `test/runner/run_all.rb` (verify: `make test-one T=test/plugins_ruby.rb` and `make test-one T=test/editor_syntax.rb` pass with unchanged snapshots).
- [x] 1.2 Delete `carat/plugins/ruby/structure.rb` and remove the tokenizer's opener counting (`opens`, `ends`, `@loop`, `structure`, `modifier_before?`, `JUMPS`, `endless?`, `starts`) from `carat/plugins/ruby/tokenizer.rb`; remove the structure check and its table from `test/plugins_ruby.rb` and its rows from the snapshot (verify: `make test-one T=test/plugins_ruby.rb`, the token and state rows unchanged; `make diagnose-one T=carat/plugins/ruby/tokenizer.rb` clean).

## 2. Documents

- [x] 2.1 Remove the sign sentence from `README.md`, the structure file, test, and design reference from `docs/codebase-map.md` area 14, and the sign from the ruby plugin's description in `docs/plugins.md` (verify: `make docs-lint` and `make lint` pass).

## 3. Verification

- [ ] 3.1 Run `make test`, `make gates`, and `make spec-validate`, and compare `make bench SCENARIOS=open-ruby` with main's recorded figures (allocations 24.0), at or under them.
