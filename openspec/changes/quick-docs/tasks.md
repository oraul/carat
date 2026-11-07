# Tasks

## 1. Markdown wrapping

- [ ] 1.1 Fix `MarkdownText.wrapped` (`carat/domain/markdown_text.rb`) so a row never breaks inside its prefix; rows in `test/domain_markdown_text.rb` for a code row, a bullet, and a quote bar before a long word.

## 2. The request and the gateway

- [ ] 2.1 Add `Domain::HoverRequest` (`carat/domain/hover_request.rb`): the ask, the request in flight, the answer, the hovering languages, and the float id; built in `EditorAssembly` and passed to the gateway.
- [ ] 2.2 In `JsonRpcLanguageGateway`, advertise hover in initialize, record `hoverProvider`, send `textDocument/hover` at the idle tick, cancel a superseded or overdue request, read only the answer in flight into bounded markdown, and include it in `waiting?`; cases in `test/adapters_hover.rb`.

## 3. The editor side

- [ ] 3.1 Add `RequestHover`, `ShowHover`, `FollowHover`, and `PinHover` under `carat/use_cases/docs/` and `DocsHandler` (`docs.hover`, `docs.pin`); wire them in `EditorAssembly`, `InputController` (the idle tick), and `HandleKey` (the per-key check); bind `K` and `<leader>dp` in `config/default.caratrc` and run `make gen-config`; cases in `test/adapters_hover.rb` for the float, scrolling, closing, pinning, and hostile text.

## 4. Docs and checks

- [ ] 4.1 Update `docs/codebase-map.md`, `docs/actions.md`, `docs/compatibility.md`, `README.md`, and `docs/backlog.md` (the plan notes and the `quick-docs-styles` follow-up); `make docs-lint` and `make gates` pass.
- [ ] 4.2 Run `make test`, `make lint`, `make diagnose`, and `make spec-validate`, all passing.
