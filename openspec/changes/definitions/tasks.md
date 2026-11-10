# Tasks

## 1. Records

- [ ] 1.1 Add `Domain::DefinitionRequest` (`carat/domain/definition_request.rb`) and `Domain::JumpList` (`carat/domain/jump_list.rb`); rows in `test/domain_jump_list.rb` for stepping, the newest-end push, the hundred-entry cap, and the same-line replacement.

## 2. The request

- [ ] 2.1 Send, cancel, and read `textDocument/definition` in `JsonRpcLanguageGateway` (capability, `definitionProvider`, `Location` and `LocationLink` answers, file URIs only, bounds, the stale-answer rule, crash and stop); checked in `test/adapters_definitions.rb`.
- [ ] 2.2 Add `RequestDefinition`, `ShowDefinition`, `VisitTarget`, `ChooseDefinition`, `FollowDefinition`, and `WalkJumps` under `carat/use_cases/definitions/`, `DefinitionHandler` in `carat/use_cases/actions/`, wire them in `EditorAssembly`, `InputController`, and `HandleKey`; `test/adapters_assembly.rb` checks the shared instances.
- [ ] 2.3 Bind `gd`, `<leader>dd`, `<C-o>`, and `<C-i>` in `config/default.caratrc` (`make gen-config`); rows in `docs/actions.md`; `test/adapters_definitions.rb` covers every scenario of the `definitions` and `jump-list` specs.

## 3. Docs and checks

- [ ] 3.1 Update `docs/compatibility.md`, `docs/codebase-map.md`, `docs/architecture.md` (roadmap item 10), `README.md`, and `docs/backlog.md` (the plan notes and the other jump commands); `make docs-lint` and `make gates` pass.
- [ ] 3.2 Run `make test`, `make lint`, `make diagnose`, and `make spec-validate`, all passing.
