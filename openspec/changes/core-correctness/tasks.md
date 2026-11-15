## 1. Tab under expandtab

- [x] 1.1 Pad from the display column in `InsertTab#call` (`carat/use_cases/insert_tab.rb`) with `Domain::DisplayWidth.column`; prove it with the `test/editor_insert.rb` rows "Expandtab after a tab" and "Expandtab after a wide character".

## 2. none unbinding

- [x] 2.1 Route a nil value in `Keymap#bind_owned` to a private `unbind` that walks with `child?` and prunes the emptied nodes (`carat/domain/keymap.rb`); prove it with the `test/domain_keymap.rb` checks "A two-key none unbinding leaves no prefix" and "A none unbinding keeps the longer bindings".

## 3. revert_to and the global marks

- [x] 3.1 Shift the global marks in `Buffer#revert_to` (`carat/domain/buffer.rb`); prove it with the `test/domain_global.rb` check "A reverted plugin edit inside a global".

## 4. timeout follow-ups

- [x] 4.1 Move the follow-ups of `HandleKey#call` into a private `follow` that `HandleKey#timeout` also ends with (`carat/use_cases/handle_key.rb`); prove it with the `test/editor_leader.rb` check "A timeoutlen binding closes the hover".

## 5. Checks

- [ ] 5.1 Run the targeted tests, `make lint`, `make diagnose-one` on the touched files, `make gates`, and `make spec-validate`.
