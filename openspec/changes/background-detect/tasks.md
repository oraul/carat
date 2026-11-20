# Tasks

## 1. The reply

- [x] 1.1 `carat/domain/terminal_background.rb` `TerminalBackground`: `QUERY`, `reply_size`, `parse` (proved by `test/domain_terminal_background.rb`)

## 2. The terminal

- [x] 2.1 `carat/ports/terminal_port.rb` `background`, `carat/doubles/fake_terminal.rb` `background` (proved by `test/drivers_ansi_terminal.rb` "the double reports no background")
- [x] 2.2 `carat/drivers/ansi_terminal.rb` sends the query at the first `read_key` after `enter` and takes the reply out of the reads (proved by `test/drivers_ansi_terminal.rb` "The first frame waits for no reply", "A dark reply", "A light reply", "A malformed reply", "No reply")

## 3. Docs

- [x] 3.1 `docs/architecture.md` ports table, `docs/codebase-map.md` areas 17 and 18 (proved by `make lint` and `make docs-lint`)

## 4. Review fixes

- [x] 4.1 `carat/drivers/ansi_terminal.rb` `read_key`: state in the comment, the spec, and the design that the rest of a reply delayed past a read timeout arrives as keys (proved by `test/drivers_ansi_terminal.rb` "A reply delayed past a timeout")
- [x] 4.2 `carat/doubles/fake_terminal.rb` `background` answers `Domain::TerminalBackground::UNKNOWN` (proved by `test/drivers_ansi_terminal.rb` "the double reports no background")
- [x] 4.3 `carat/domain/terminal_background.rb` the luma weights are the constant `LUMA_WEIGHTS` (proved by `test/domain_terminal_background.rb`)
- [x] 4.4 `docs/architecture.md` the ports paragraph restored, only the `TerminalPort` row changed (proved by `make lint`)
- [x] 4.5 `carat/drivers/ansi_terminal.rb` the `read_key` comment rewrapped (proved by `make lint`)
