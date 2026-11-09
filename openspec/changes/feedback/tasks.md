# Tasks

## 1. Message history and :messages

- [ ] 1.1 Add `Domain::MessageHistory` (`carat/domain/message_history.rb`) and keep it in `Domain::EditorState`, recorded by `show` for one-line texts, with `show_output` for unrecorded output; prove it in `test/domain_messages.rb`
- [ ] 1.2 Add `UseCases::MessagesCommandHandler` (`:mes[sages]`, `:messages clear`) registered before `:LspStart` in `EditorAssembly`, its rows in `docs/compatibility.md`; prove it in `test/editor_messages.rb` and the spelling check of `test/use_cases_ex.rb`

## 2. Notifications

- [ ] 2.1 Add `Domain::Notices` (`carat/domain/notices.rb`): add with the history, at most three, deadlines by severity, expire, wait; prove it in `test/domain_messages.rb`
- [ ] 2.2 Wire one `Notices` in `EditorAssembly` into `InputController` (expiry on idle reads and the read timeout) and `FramePresenter` (boxes through the float key, plain drawing from `plain=` set at `open`); prove placement, stacking, expiry, keys under a box, and plain drawing in `test/editor_messages.rb`
- [ ] 2.3 Read `window/showMessage` in `JsonRpcLanguageGateway` into a notice with the text cleaned and capped; prove it in `test/adapters_language_gateway.rb`

## 3. Progress segment

- [ ] 3.1 Add the progress to `Domain::StatusSlots` and the `PROGRESS` kind to `Adapters::StatusBar` (bar, reducedmotion, plain); prove it in `test/adapters_status_bar.rb`
- [ ] 3.2 Fill and clear the progress from `$/progress` in `JsonRpcLanguageGateway`; prove it in `test/adapters_language_gateway.rb`

## 4. Docs, bookkeeping, and checks

- [ ] 4.1 Add the Messages and notifications table to `docs/compatibility.md` (each kind's placement, expiry, and history) and the progress row of the status bar; map the new files in `docs/codebase-map.md`
- [ ] 4.2 Do the plan's backlog bookkeeping in `docs/backlog.md` and delete the dead `Motions.char_class` and `keyword?` (`carat/use_cases/motions.rb`), checked by `make test`
- [ ] 4.3 Run `make gates`, `make spec-validate`, `make docs-lint`, and the touched tests; confirm `lh` allocations per key with `make bench-budget`
