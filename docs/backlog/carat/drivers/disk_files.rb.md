# Backlog: carat/drivers/disk_files.rb

## DiskFiles#stat makes four system stats per path

- Where: `DiskFiles#stat` in `carat/drivers/disk_files.rb` line 57, `File.size`, `File.mtime`, `File.directory?`, and `File.stat` for one path. Advisory of the periodic quality review at 389c118.
- Why it matters: every open, explorer listing, and plugin stat pays four system calls where one would do, and the answers can come from different moments.
- Fix outline: take the size, mtime, directory, and regular flags from one `File.stat` where the pinned Spinel supports them, else record why in `docs/spinel-notes.md`. Queued as `file-access-tidy`.
- Merged: ### DiskFiles#stat makes four system stats per path
- Location: carat/drivers/disk_files.rb:53 (`stat`), called by list_tree.rb, probe_path.rb, rc_config_gateway.rb, and editor_assembly.rb
- Why: a non-link path pays `File.symlink?`, `File.exist?`, then `File.size`, `File.mtime`, `File.directory?`, and `File.stat(path).file?`, each its own system call, on every tree listing and probe; split from lsp-tidy by the plan and queued as `lsp-tidy-c`
- Fix: take one `File.lstat` and, for a link, one `File.stat`, and read the size, mtime, directory, and regular flags from those; a test over test/drivers_disk_files.rb's directory keeps the flags of every row
- Also: docs/spinel-notes.md, test/drivers_disk_files.rb
- Category: editor
- Added: 2026-11-03

### MakePath and the project .caratrc check follow a link swapped after the probe (sprint-14 sweep security Low (3), Low (3))

- Location: carat/drivers/disk_files.rb:33; carat/adapters/rc_config_gateway.rb:70.
- Why: a probe then a write or read that follows links lets a symbolic link planted between them create a file outside the root or read a linked .caratrc.
- Fix outline: create with exclusive no-follow opens and mkdir; open the project file without following links and judge it by fstat. Queued in `file-access-tidy` and `project-config-guards`.
- Also: carat/adapters/rc_config_gateway.rb
- Category: security
- Added: 2026-11-17
