# Tasks

## 1. Records

- [x] 1.1 Add `Domain::DefinitionRequest` (`carat/domain/definition_request.rb`) and `Domain::JumpList` (`carat/domain/jump_list.rb`); rows in `test/domain_jump_list.rb` for stepping, the newest-end push, the hundred-entry cap, and the same-line replacement.

## 2. The request

- [x] 2.1 Send, cancel, and read `textDocument/definition` in `JsonRpcLanguageGateway` (capability, `definitionProvider`, `Location` and `LocationLink` answers, file URIs only, bounds, the stale-answer rule, crash and stop); checked in `test/adapters_definitions.rb`.
- [x] 2.2 Add `RequestDefinition`, `ShowDefinition`, `VisitTarget`, `ChooseDefinition`, `FollowDefinition`, and `WalkJumps` under `carat/use_cases/definitions/`, `DefinitionHandler` in `carat/use_cases/actions/`, wire them in `EditorAssembly`, `InputController`, and `HandleKey`; `test/adapters_assembly.rb` checks the shared instances.
- [x] 2.3 Bind `gd`, `<leader>dd`, `<C-o>`, and `<C-i>` in `config/default.caratrc` (`make gen-config`); rows in `docs/actions.md`; `test/adapters_definitions.rb` covers every scenario of the `definitions` and `jump-list` specs.
- [x] 2.4 Bind the pick list's Enter as `keymap.pick <CR> definition.choose` in `config/default.caratrc` (`make gen-config`), read by `Keymap.pick_from` and checked by `Keymap#add_checked` in no editor mode, built once in `EditorAssembly` and held by `ShowDefinition`; rows in `test/domain_keymap.rb`, `test/adapters_definitions.rb`, and `test/adapters_assembly.rb`.

## 3. Docs and checks

- [x] 3.1 Update `docs/compatibility.md`, `docs/codebase-map.md`, `docs/architecture.md` (roadmap item 10), `README.md`, and `docs/backlog.md` (the plan notes and the other jump commands); `make docs-lint` and `make gates` pass.
- [x] 3.2 Run `make test`, `make lint`, `make diagnose`, and `make spec-validate`, all passing.
