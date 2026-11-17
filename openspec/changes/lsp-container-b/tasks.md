# Tasks

## 1. End only the spawned server

- [x] 1.1 Signal `TERM` to the handle's own pid before detaching in `ProcessRunner#stop` (`carat/drivers/process_runner.rb`), the contract in `carat/ports/process_port.rb`; verify with "Stopping a server ends only that server" in `test/drivers_process_runner.rb`
- [x] 1.3 Trap `PIPE` once in `ProcessRunner#initialize`, so a write to a server stopped while its writer thread still holds bytes fails with `EPIPE` instead of ending carat; verify with "Stopping a stalled server keeps the editor running" in `test/drivers_process_runner.rb`
- [x] 1.2 Show quit and `:LspRestart` stopping only the started server's handle; verify with "Quit stops only the started server" in `test/adapters_language_gateway.rb` and "LspRestart stops only the old server" in `test/editor_lsp.rb`

## 2. Settle a language's command once

- [x] 2.1 Keep each language's settled program in `JsonRpcLanguageGateway#head_of`, used by `command?` and `hold` (`carat/adapters/json_rpc_language_gateway.rb`); verify with "An idle tick with no server reads no configuration line" in `test/adapters_language_gateway.rb`

## 3. Documents

- [x] 3.1 Update `docs/architecture.md` (the `ProcessRunner` entry) for the stop signal, `docs/codebase-map.md` area 17 for both, and the README language server paragraph; verify `make docs-lint` and `make gates` pass
