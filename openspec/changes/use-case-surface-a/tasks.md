# Tasks

## 1. Edge-case tests first

- [x] 1.1 `test/editor_palette.rb`: a text of colons alone lists every entry, a trailing blank is part of the text, and the palette over an empty buffer lists every entry and Esc leaves the buffer empty (proved by the tests' labels)
- [x] 1.2 `test/editor_key_hints.rb`: Esc with no hints shown closes nothing, the hints show from the last line and over an empty buffer, and Esc leaves the cursor and text (proved by the tests' labels)

## 2. The wiring ledger

- [x] 2.1 `carat/adapters/wiring_ledger.rb`: `WiringLedger` with `record` and `held`, required by `carat.rb` (proved by the guard's self-check in `test/adapters_assembly.rb`)
- [x] 2.2 `carat/adapters/editor_assembly.rb`: build the ledger first, keep it in `wiring`, and record each discovery use case's shared objects after its construction (proved by `test/adapters_assembly.rb`)

## 3. The discovery area without readers

- [x] 3.1 `carat/use_cases/discovery/`: `ShowKeyHints`, `HideKeyHints`, `OpenPalette`, and `FollowPalette` replace their readers with `# @rbs @name: Type` lines (proved by `test/editor_key_hints.rb`, `test/editor_palette.rb`, and `make lint`)
- [x] 3.2 `test/adapters_assembly.rb`: read the discovery holders through `a.wiring.held` and check that an unrecorded pair is a stranger (proved by the test itself)
- [x] 3.3 `test/lint.rb`: the shared-holder rule accepts a ledger record that matches the construction and is checked by the test, and `READERLESS_DIRS` refuses a public reader in `carat/use_cases/discovery/`, each branch in the self-tests (proved by `make lint`)

## 4. Docs and measurements

- [x] 4.1 `docs/architecture.md` (sections 5, 8, 10), `docs/codebase-map.md` (area 4), `docs/examples.md`, and `docs/spinel-notes.md` describe the ledger and the readerless directories (proved by `make docs-lint` and `make lint`)
- [x] 4.2 Measure analysis time and rounds of both compile roots, the binary's size, and time per key on main and on the branch for the pull request (`make metrics`)

## 5. Review fixes

- [x] 5.1 `test/lint.rb`: a ledger record whose slot is not a keyword of the holder's construction line fails, so `test/adapters_assembly.rb` drops its hand-copied slot lists and `WiringLedger` drops `slots` and its parallel arrays (proved by the self-test "the shared holder rule takes a ledger record ...")
- [x] 5.2 `test/lint.rb`: a ledger record of a slot the holder does not store as `@slot = slot` fails, so a readerless holder cannot keep another keyword's object under a recorded name (proved by the same self-test)
- [x] 5.3 `test/lint.rb`: the assembly's text is read once for the holder rule, and `ledger_problems_of` says only the self-test uses it (proved by `make lint`)
- [x] 5.4 `test/editor_key_hints.rb` and `test/editor_palette.rb`: the empty-buffer edge cases use one `empty_session` helper per file (proved by the tests' labels)
- [x] 5.5 `test/lint.rb`: a holder under a directory of `READERLESS_DIRS` stores each keyword its `initialize` signature types shared as `@keyword = keyword`, with a matching ledger record, so dropping both the record and the `held` line of a keyword stored under another name fails (proved by the self-test "a readerless holder stores each keyword its signature types shared under its own name, with a ledger record")
