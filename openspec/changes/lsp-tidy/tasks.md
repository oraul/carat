# Tasks

## 1. The gateway

- [ ] 1.1 `carat/adapters/json_rpc_language_gateway.rb` `path_of` drops a URI whose decoded path holds a `.` or `..` segment (proved by "A target with a dot segment is dropped" in `test/adapters_definitions.rb`)
- [ ] 1.2 `carat/adapters/json_rpc_language_gateway.rb` `sync_buffer` opens only a buffer under the working directory (proved by "A file outside the working directory is never opened on the server" in `test/adapters_language_gateway.rb`)
- [ ] 1.3 `carat/adapters/json_rpc_language_gateway.rb` `poll` keeps the save of a buffer whose server starts and `sync_buffer` sends `didSave` after `didOpen` (proved by "A save while the server starts is sent once it is ready" in `test/adapters_language_gateway.rb`)
- [ ] 1.4 `carat/doubles/fake_processes.rb` counts every spawn as `attempts`, and a test shows a refused command is not spawned again at the next idle tick (proved by "a missing command leaves the slot empty and later idle ticks start nothing" in `test/adapters_language_gateway.rb`)

## 2. The process runner

- [ ] 2.1 `carat/drivers/process_runner.rb` `stop` kills a child that has not ended `STOP_SECONDS` after TERM, and `carat/ports/process_port.rb` says so (proved by "A server ignoring its end of input and TERM is killed" in `test/drivers_process_runner.rb`)
- [ ] 2.2 `carat/drivers/process_runner.rb` `drain` closes the outbox on a failed write and `write` answers false for a closed one (proved by "A server whose input broke takes no more input" in `test/drivers_process_runner.rb`)

## 3. Docs and findings

- [ ] 3.1 `docs/architecture.md` section 8.4 and `docs/codebase-map.md` area 17 describe the working-directory rule, the save kept for a starting server, and the KILL after the stop's grace (proved by `make docs-lint` and `make lint`)
- [ ] 3.2 Append the four queued headings and the request finding to `docs/findings/lsp-tidy.md` with `>>`
