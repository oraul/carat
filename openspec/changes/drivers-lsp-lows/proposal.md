# Proposal

## Why

Two security Lows and eight tidies in the drivers and the language server client remain from the sprint-14 sweep and two periodic reviews. `MakePath` probes that its target is absent, then creates it with `File.write`, which follows a symbolic link planted at the target between the probe and the write, so a plugin's or the explorer's create can truncate a file outside the tree. A server's `textDocument/publishDiagnostics` is kept for any URI it names, so a hostile server can grow the kept diagnostics without bound. It is outside the roadmap of `docs/architecture.md` section 12: a backlog tidy of security Lows and code findings.

Re-verified at 15b9c5e: the project `.caratrc` is already opened with `O_NOFOLLOW` (`read_no_link`, `rc_config_gateway.rb:69`), so the "swapped for a link" half of the first Low no longer holds for it; what still holds is that its kind is judged by the path again after the open, since a `File#stat` at the pinned Spinel re-reads the path, not the descriptor, and that a FIFO opened by `File.open` while other threads run waits for a writer in Spinel's runtime whatever `O_NONBLOCK` asked. The other items hold as the queue entry names them, at the lines the plan notes give.

## What Changes

- Add `FilePort#create(path)`: an exclusive, no-follow create (`O_CREAT | O_EXCL | O_NOFOLLOW`) of an empty regular file that refuses anything at the path, a link included; `MakePath` creates files through it, so a link planted after the probe is never written through.
- `DiskFiles#read` and `#read_no_link` open with `IO.sysopen` and judge the kind on the descriptor (`IO.for_fd(fd).stat`, an fstat), so a path swapped after the open is not judged again, and a FIFO is refused at once even while a language server's threads run.
- `DiskFiles#stat` reads one `File.stat` (after `File.symlink?`) instead of four `File` calls.
- The gateway keeps a publish only for a document the server was told is open (`server.versions`); any other URI is dropped.
- Tidies: `AnsiTerminal`'s `NO_COLOR` read gets a test; `ProcessRunner` requires the framer, the service message, and the queue port it names; the gateway's `start` and `restart` share their tail; `apply(set)` becomes `draw_published(icons)` without the branch `Buffer#set_diagnostics` already makes; `listed` becomes private; `request` answers 0 when the write crashed the server, so a failed completion send leaves nothing in flight and the input stops polling; `utf16_length` moves to `Domain::Utf8.utf16_length`, counting each malformed byte as one unit as the module's decoder does.
- `docs/spinel-notes.md` records the two Spinel facts above.

Extra, named: the `request` fix covers the hover, definition, signature, and symbol asks too, which share its return; a malformed byte in a position's line now counts one UTF-16 unit (it counted 0 for a stray continuation byte, 2 for a truncated four-byte lead).

Out of scope: `SaveFile`'s write (the user's own path), the user file's link (trusted by design), a parent directory swapped for a link between `ResolveInside` and the create (no `openat` in Spinel; recorded as a finding), and any `tools/rules.sh` edit.

Assumptions:

- A server publishes diagnostics only for documents it was told about, as ruby-lsp does; a workspace-wide publish is dropped until the file is opened.
- The permissions of a created file stay Ruby's default, 0666 under the umask, as `File.write` gave.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `plugin-host`: a create never goes through a link planted after its checks.
- `language-server`: diagnostics are kept only for opened documents.
- `config-files`: a file read is judged on its opened descriptor and never waits on a FIFO.

## Impact

- `carat/ports/file_port.rb`, `carat/drivers/disk_files.rb`, `carat/doubles/memory_files.rb`, `carat/use_cases/files/make_path.rb`, `carat/drivers/process_runner.rb`, `carat/adapters/json_rpc_language_gateway.rb`, `carat/domain/utf8.rb`; tests `test/drivers_disk_files.rb`, `test/drivers_ansi_terminal.rb`, `test/adapters_language_gateway.rb`, `test/adapters_server_completions.rb`, `test/domain_utf8.rb`, `test/adapters_hover.rb`; `docs/spinel-notes.md` (the stat handle and the FIFO open).
- README.md: unchanged, no user-visible command, option, or key changes; the refusals are security hardening of existing creates and reads.
- docs/architecture.md: changed, the `FilePort` row gains `create(path)` and the fstat read.
- docs/codebase-map.md: changed, the area 17 lines of `FilePort`, `DiskFiles`, and the gateway, and the `Utf8` line.
- CLAUDE.md: unchanged, no agent, workflow, command, or gate changes.
