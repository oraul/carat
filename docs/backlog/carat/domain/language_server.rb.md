# Backlog: carat/domain/language_server.rb

## The language server client has loose ends

- Where: at `lsp-diagnostics`: `LanguageServer#words` (`carat/domain/language_server.rb` line 11) is stored and never read; `LspRestartCommandHandler.register(table, services)` (`carat/use_cases/ex/lsp_restart_command_handler.rb` line 35) takes its collaborator positionally; `RpcFramer#refuse` (`carat/domain/rpc_framer.rb` line 82) answers false only for `return refuse`, which needs a `BOOL_COMMANDS` entry in `test/lint.rb`; `json_rpc_language_gateway.rb`, `editor_assembly.rb`, `input_controller.rb`, `lsp_restart_command_handler.rb`, and `process_runner.rb` omit `require_relative` lines for files they name. Quality advisories of `lsp-diagnostics`.
- Why it matters: dead code, an odd signature, and a lint exemption that exists for an idiom each mislead the next reader; sibling files require what they name.
- Fix outline: drop `words` or use it for the restart message; `register(table, services:)` with `services: @services` in `EditorAssembly`; make `refuse` void, return false after it, and drop the lint entry; add the missing `require_relative` lines. Queued in `lsp-client-tidy`.
- Also: carat/use_cases/ex/lsp_restart_command_handler.rb, carat/domain/rpc_framer.rb, test/lint.rb
- Category: ide
- Added: 2026-11-07
