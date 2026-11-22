## 1. File creates and reads

- [x] 1.1 Add `FilePort#create`, `DiskFiles#create` (exclusive, no-follow), and `MemoryFiles#create`; `MakePath` creates files through it (test: `test/drivers_disk_files.rb`, a link planted after the checks)
- [x] 1.2 `DiskFiles#read_open` opens with `IO.sysopen` and judges the kind by the descriptor's fstat (test: `test/drivers_disk_files.rb`, a FIFO refused at once while a thread runs)
- [x] 1.3 `DiskFiles#stat` reads one `File.stat` after `File.symlink?` (test: the stat table of `test/drivers_disk_files.rb`)

## 2. Language server client

- [x] 2.1 `published` keeps only a URI the server was told is open (test: `test/adapters_language_gateway.rb`)
- [x] 2.2 `request` answers 0 when the write crashed the server (test: `test/adapters_server_completions.rb`)
- [x] 2.3 `start` and `restart` share their tail; `apply` becomes `draw_published` without the needless branch; `listed` is private (tests: `test/adapters_language_gateway.rb`, `test/editor_lsp.rb`)
- [x] 2.4 Move `utf16_length` to `Domain::Utf8.utf16_length` (test: `test/domain_utf8.rb`)

## 3. Drivers

- [x] 3.1 `ProcessRunner` requires the framer, the service message, and the queue port (test: `test/drivers_process_runner.rb`)
- [x] 3.2 Test `AnsiTerminal`'s `NO_COLOR` read (test: `test/drivers_ansi_terminal.rb`)

## 4. Docs

- [x] 4.1 Update `docs/architecture.md` (the `FilePort` row), `docs/codebase-map.md` (area 17 and the `Utf8` line), and `docs/spinel-notes.md` (the stat handle and the FIFO open)

## Quality review

- [x] 5.1 The `request` fix also changes the hover, definition, signature, and symbol asks, untested: add the failed hover send to `test/adapters_hover.rb` (fixed)
- [x] 5.2 A parent directory swapped for a link after `ResolveInside` still redirects the create: needs `openat`, which Spinel lacks; recorded in `docs/findings/drivers-lsp-lows.md`; the interim delete after a second resolve is not applied, since a link swapped again before the delete could remove an existing file elsewhere (design, Risks)
