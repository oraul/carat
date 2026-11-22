# Tasks

## 1. Security: the project file's text-entry and prompt bindings

- [x] 1.1 `Config` (`carat/domain/config.rb`): `TEXT_MODES` and `TEXT_BINDABLE`, `project_bindable_in?` answering from them in a text-entry mode, so `mode.normal` and any action that is not an insert, cursor, scroll, completion, or palette-list action is refused there and the trusted files' such keys are held (proved by `test/adapters_config_gateway.rb`, "a project file cannot leave a text-entry mode" and "a project file cannot unbind the Esc of insert mode, cmdline mode, or the completion popup", scenarios "The project file binds insert-mode Enter to normal mode" and "The project file unbinds insert-mode Escape", and the editor check that insert `<CR>` still splits the line)
- [x] 1.2 `Config#binding_problem`: a prompt opener on keys every one of which is typed while editing text is refused (`typed_while_editing?`) (proved by `test/adapters_config_gateway.rb`, "a project file cannot bind a prompt to keys typed while editing text", scenario "The project file binds a prompt to keys typed while editing text"; the write-or-quit check's `;` line moved to `<F5>`, `test/domain_rc_parser.rb`'s untrusted `k` to `<F4>`; `test/editor_completion.rb` and `test/editor_normal.rb` bind their insert-mode `buffer.next` and `jk mode.normal` from the user file)
- [x] 1.3 Each new check fails with its fix reverted (rule 7), run through `make test-one T=test/adapters_config_gateway.rb`

## 2. Tidies

- [x] 2.1 Remove `Keymap.leader_from` (`carat/domain/keymap.rb`); `Keymap.pick_from`, `Keymap#add_checked`, and `EditorAssembly` read `Config#leader`; the tests in `test/domain_keymap.rb`, `test/config_sync.rb`, `test/adapters_config_gateway.rb`, and `test/adapters_assembly.rb` call `leader` (proved by those tests' leader checks, labels kept)
- [x] 2.2 `Config`'s settings read only through `count` and `line_at`: `JsonRpcLanguageGateway#root_line` uses `count`, and the pin's comment says why it stays `Array[untyped]` (proved by `test/adapters_language_gateway.rb`, its `lsp.root` checks unchanged)

## 3. Docs

- [x] 3.1 README's project-file sentence, `docs/architecture.md` section 7's project-file line, and `docs/codebase-map.md` (`config.rb`, `keymap.rb`)

## Quality review

- [x] Q.1 `Config#typed_while_editing?` (then `typed_as_text?`) let a prompt opener on `<Up>` or another editing key through, so `<Up>` could open the command line and the next `<Up>` recall an earlier command; the arrows, Home, End, the Page keys, Delete, and Escape now count as keys typed while editing, only a function, Alt, or other control key making the keys allowed (fixed; `test/adapters_config_gateway.rb`, `<Up>` and `<Esc><Del>` rows)
- [x] Q.2 The completion popup's `<Esc>` (`completion.close`) was not held, so `keymap.completion <Esc> completion.next` kept the popup open on every Escape; `held_keys` holds a key bound to `CLOSE_COMPLETION` (fixed; "a project file cannot unbind the Esc of insert mode, cmdline mode, or the completion popup")
- [x] Q.3 `palette.next` and `palette.previous` were bindable on any key in cmdline mode, so a letter would move the palette's choice under the filter typed and Enter run another action; they are out of `TEXT_BINDABLE` (fixed; "a project file cannot leave a text-entry mode", the `s palette.next` row)
- [x] Q.4 `TEXT_BINDABLE` named families, so a later `insert.*` that leaves the mode would be allowed at once; it names seventeen actions whole, and `test/use_cases_actions.rb` checks each is registered and allowed (fixed; "every action a project file may bind in a text-entry mode is registered and allowed", and the `cursor.line_start` row)
- [x] Q.5 The tasks were unticked at the reviewed commit; they are ticked (fixed)
- [x] Q.6 A multi-byte key under the typed-text rule had no test; the `é palette.open` row proves it is refused (fixed)
