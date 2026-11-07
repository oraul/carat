# Tasks

## 1. The request record

- [x] 1.1 Add `Domain::SignatureRequest` (`carat/domain/signature_request.rb`): the anchor, the serials, the request in flight, the cleaned answer and its marked range (`keep`), `ask`, `stop`, `active?`, `at?`, `helps?`, `waiting?`, and `open_paren`; rows in `test/domain_signature_request.rb` for the scan, the cleaning, and the cap.

## 2. The gateway

- [x] 2.1 In `JsonRpcLanguageGateway`, advertise signature help in initialize, record `signatureHelpProvider`, send `textDocument/signatureHelp` debounced at the idle tick, cancel a superseded or overdue request through `cancel_request`, read only the newest answer into `SignatureRequest#keep`, forget a stopped server's request, and include it in `waiting?`; cases in `test/adapters_signature.rb`, including both stale-answer orders.

## 3. The editor side

- [x] 3.1 Add `FloatWindow#mark_from` and `mark_to` and paint them in `Visual` in `FramePresenter#paint_float_row`; a row in `test/adapters_signature.rb` reads the cell groups.
- [x] 3.2 Add `RequestSignature`, `ShowSignature`, and `FollowSignature` under `carat/use_cases/docs/`; wire them in `EditorAssembly`, `HandleKey` (the trigger and the follow check), and `InputController` (the idle tick); cases in `test/adapters_signature.rb` for opening, following, closing on `)`, `Esc`, another row, an empty answer, and hostile text; the shared instances in `test/adapters_assembly.rb`.

## 4. Docs and checks

- [x] 4.1 Update `docs/architecture.md` (section 5.3), `docs/codebase-map.md`, `docs/compatibility.md`, `README.md`, and `docs/backlog.md` (the plan notes and the cancel-copies entry); `make docs-lint` and `make gates` pass.
- [x] 4.2 Run `make test`, `make lint`, `make diagnose`, and `make spec-validate`, all passing.
