# Tasks

## 1. The reply

- [ ] 1.1 `carat/domain/terminal_background.rb` `TerminalBackground`: `QUERY`, `reply_size`, `parse` (proved by `test/domain_terminal_background.rb`)

## 2. The terminal

- [ ] 2.1 `carat/ports/terminal_port.rb` `background`, `carat/doubles/fake_terminal.rb` `background` (proved by `test/drivers_ansi_terminal.rb` "the double reports no background")
- [ ] 2.2 `carat/drivers/ansi_terminal.rb` writes the query on `enter` and takes the reply out in `read_key` (proved by `test/drivers_ansi_terminal.rb` "The first frame waits for no reply", "A dark reply", "A light reply", "A malformed reply", "No reply")

## 3. Docs

- [ ] 3.1 `docs/architecture.md` ports table, `docs/codebase-map.md` areas 17 and 18 (proved by `make lint` and `make docs-lint`)
