# Tasks

## 1. Domain

- [x] 1.1 `carat/domain/json.rb`: nesting limit of 64 and illegal UTF-8 bytes read and written as U+FFFD. Tested by `test/json.rb` (hostile rows).
- [x] 1.2 `carat/domain/rpc_framer.rb`, `control_text.rb`, `service_message.rb`, `diagnostic.rb`: framing with its limits, control stripping, the queue's message, the diagnostic value. Tested by `test/domain_rpc_framer.rb`.
- [x] 1.3 `carat/domain/status_slots.rb` (`lsp_label`, `set_lsp`, the five states) and `carat/adapters/status_bar.rb` (the label, the groups). Tested by `test/adapters_status_bar.rb`.

## 2. Ports, drivers, doubles

- [x] 2.1 `carat/ports/process_port.rb`, `message_queue_port.rb`, `language_service_port.rb`; `carat/doubles/fake_processes.rb`, `memory_queue.rb`, `fake_language_services.rb`; `SaveFile` reports writes. Tested through `test/adapters_language_gateway.rb`.
- [x] 2.2 `carat/drivers/process_runner.rb` (spawn, reader thread, stop) and `runtime_queue.rb`. Tested by `test/drivers_process_runner.rb` over `cat`.

## 3. Gateway and wiring

- [x] 3.1 `carat/domain/language_server.rb` and `carat/adapters/json_rpc_language_gateway.rb`: start, initialize, documents, progress, diagnostics, server requests, crash, stop. Tested by `test/adapters_language_gateway.rb`.
- [x] 3.2 `EditorAssembly` (`processes:`, `messages:`, the gateway), `InputController` (poll on an idle tick), `EditorHarness`, `bin/carat.rb` (drivers, stop in `ensure`). Tested by `test/adapters_assembly.rb` and `test/editor_lsp.rb`.
- [x] 3.3 `carat/use_cases/ex/lsp_restart_command_handler.rb` for `:LspRestart` with its `docs/compatibility.md` row. Tested by `test/editor_lsp.rb` and `test/use_cases_ex.rb`.

## 4. Docs and records

- [x] 4.1 `docs/codebase-map.md`, `docs/architecture.md` sections 6 and 8, `README.md`, `docs/compatibility.md` bar row. Checked by `make gates` and `make docs-lint`.
- [x] 4.2 `docs/backlog.md`: remove the Json entry, narrow the slots entry, add the plan's seven entries (so the package step adds none of `build/plan/backlog.md` again), update the plugin API and delivered-list entries, queue the `in_window` notes in `float-tidy`, and add this change's three follow-ups. Checked by `make docs-lint`.
- [x] 4.3 `make gates`, `make spec-validate`, bench `lh` allocations unchanged.

## 5. Review fixes

- [x] 5.1 Security: a server starts on its own only under a root of `language.trusted_roots` (defaults and user file only, `Domain::Config::TRUSTED_ROOTS`); elsewhere the slot reads `untrusted :LspStart`, and `carat/use_cases/ex/lsp_start_command_handler.rb` adds `:LspStart` through `LanguageServicePort#start`. Tested by `test/adapters_language_gateway.rb` (an untrusted directory spawns nothing, the roots), `test/editor_lsp.rb`, `test/domain_rc_parser.rb`, and `test/adapters_status_bar.rb`.
- [x] 5.2 Quality: `CLAUDE.md` Stack and `docs/architecture.md` section 13 say a reader and a writer thread per language server. Checked by `make gates`.
- [x] 5.3 Quality: `:LspStart` drops a crashed or stopped server's entry and launches a new one (`JsonRpcLanguageGateway#start`), no longer a silent no-op. Tested by `test/editor_lsp.rb`.
