# Tasks

## 1. Verify Data under Spinel

- [x] 1.1 Compile and run a probe program with the pinned Spinel covering construction, equality, hashing, hash-key lookup, frozen writes, `with`, `to_h`, pattern matching, and the subclass form with inline RBS; record the results in design.md

## 2. Convert the values

- [x] 2.1 Convert `carat/domain/position.rb` and `range.rb` to `Data` subclasses, dropping the hand-written constructors, readers, and `==`; verify with `test/domain_buffer.rb`
- [x] 2.2 Convert `carat/domain/ex_command.rb`, `KeyNotation::Result` in `key_notation.rb`, and `KeymapMatch` in `keymap.rb`; verify with `test/domain_ex_grammar.rb`, `test/domain_keys.rb`, and `test/domain_keymap.rb`
- [x] 2.3 Convert `carat/use_cases/outcome.rb`; verify with `test/use_cases_ex.rb` and `test/editor_cmdline.rb`
- [x] 2.4 Add assertions to `test/domain_buffer.rb` for value equality, hashing, hash-key lookup, frozenness, and `with` copies of `Position` and `Range`; regenerate its snapshot with `make snapshots`

## 3. Tooling and conventions

- [x] 3.1 Change the `diagnose` target to pass `--skip behavior` to `spinel-doctor`, with the reason in the target comment
- [x] 3.2 Record the `Data` convention in `CLAUDE.md` and `docs/architecture.md`, and mark `Position` and `Range` as `Data` values in the architecture's entity list

## 4. Verify

- [x] 4.1 Run `make check` (build, gen-config, test, diagnose) under Spinel; all 16 test programs pass and `spinel-doctor` reports clean on every compile root
