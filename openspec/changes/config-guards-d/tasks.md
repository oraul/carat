# Tasks

## 1. Security: the project file's text-entry and prompt bindings

- [ ] 1.1 `Config` (`carat/domain/config.rb`): `TEXT_MODES` and `TEXT_BINDABLE`, `project_bindable_in?` answering from them in a text-entry mode, so `mode.normal` and any action that is not an insert, cursor, scroll, completion, or palette-list action is refused there and the trusted files' such keys are held (proved by `test/adapters_config_gateway.rb`, "a project file cannot leave a text-entry mode" and "a project file cannot unbind insert-mode or cmdline-mode Esc", scenarios "The project file binds insert-mode Enter to normal mode" and "The project file unbinds insert-mode Escape", and the editor check that insert `<CR>` still splits the line)
- [ ] 1.2 `Config#binding_problem`: a prompt opener on keys every one of which is typed as text is refused (proved by `test/adapters_config_gateway.rb`, "a project file cannot bind a prompt to keys typed as text", scenario "The project file binds a prompt to keys typed as text"; the write-or-quit check's `;` line moved to `<F5>`)
- [ ] 1.3 Each new check fails with its fix reverted (rule 7), run through `make test-one T=test/adapters_config_gateway.rb`

## 2. Tidies

- [ ] 2.1 Remove `Keymap.leader_from` (`carat/domain/keymap.rb`); `Keymap.pick_from`, `Keymap#add_checked`, and `EditorAssembly` read `Config#leader`; the tests in `test/domain_keymap.rb`, `test/config_sync.rb`, `test/adapters_config_gateway.rb`, and `test/adapters_assembly.rb` call `leader` (proved by those tests' leader checks, labels kept)
- [ ] 2.2 `Config`'s settings read only through `count` and `line_at`: `JsonRpcLanguageGateway#root_line` uses `count`, and the pin's comment says why it stays `Array[untyped]` (proved by `test/adapters_language_root.rb` or the language gateway tests that cover `lsp.root`, unchanged)

## 3. Docs

- [ ] 3.1 README's project-file sentence, `docs/architecture.md` section 7's project-file line, and `docs/codebase-map.md` (`config.rb`, `keymap.rb`)
