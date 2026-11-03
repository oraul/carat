# Tasks

## 1. Illegal bytes in configuration lines

- [x] 1.1 `carat/domain/rc_parser.rb`: refuse a line holding a byte outside a well-formed UTF-8 sequence with `illegal byte`; rows in `test/domain_rc_parser.rb` (a lone byte, a truncated sequence, an overlong form, a surrogate, in a key, a word, a quoted word, and a comment; valid UTF-8 kept)
- [x] 1.2 `carat/domain/keymap.rb`: `Keymap.action_name?` through `RcParser.key?`, `ACTION_NAME` removed; rows in `test/domain_keymap.rb` (illegal bytes asked of `action_name?`; an illegal byte in a binding of each config scope reported by `add_checked`, in `add_lines` and `from_lines`)
- [x] 1.3 Illegal bytes in each scope through the loaded configuration: rows in `test/domain_rc_parser.rb` for the `option`, `keymap`, `plugin`, and `language` scopes, and a manifest binding and option line in `test/domain_plugin_manifest.rb`

## 2. tabstop and shiftwidth bounds

- [x] 2.1 `carat/domain/options.rb`: bound tabstop to 1..9999 and shiftwidth to 0..9999 in `apply`; rows in `test/domain_options_config.rb` (999999999, 10000, 9999, 0, 1)

## 3. The file port reads only bounded regular files

- [x] 3.1 `carat/domain/path_info.rb`: the `regular` member; `carat/ports/file_port.rb`: `read(path, limit)` and `real_path(path)`; `carat/drivers/disk_files.rb`: non-blocking open, check of the opened file, bounded read, `File.file?`, `File.realpath`; `carat/doubles/memory_files.rb`: `special`, `link_to`, `real_path`, the bounded read
- [x] 3.2 New `test/drivers_disk_files.rb` over a directory under `build/`: stat and read of a regular file, a symlink to `/dev/zero`, a FIFO, a directory, a file one byte over the limit and one at it, and `real_path` through a linked directory

## 4. The configuration gateway refuses hostile files

- [x] 4.1 `carat/domain/config.rb`: `refuse(source, reason)` in place of `unreadable`; `carat/adapters/rc_config_gateway.rb`: refuse a linked project file, a non-regular file, and one above 1 MiB; rows in `test/adapters_config_gateway.rb` (symlink, FIFO, device, huge, a linked user file read, order of the reports)

## 5. OpenFile refuses what is not a regular file of bounded size

- [x] 5.1 `carat/use_cases/files/open_file.rb`: Vim's messages for a directory and a non-regular file, E484 above 64 MiB, the bounded read; rows in `test/editor_cmdline.rb` (directory, FIFO, device, huge, linked regular file) and the `docs/compatibility.md` row

## 6. MakePath refuses a create through a link that leaves the root

- [x] 6.1 `carat/use_cases/files/make_path.rb`: compare the real paths of the parent and the root; rows in `test/use_cases_plugin_files.rb` (linked parent outside, linked parent inside, linked root) and a row in `test/editor_explorer.rb` for the explorer's `a`

## 7. Smoke test and documentation

- [ ] 7.1 `test/smoke_editor.rb`: start the release binary in a project whose `.caratrc` is a symlink to `/dev/zero`, then in one whose `.caratrc` holds an illegal byte and a huge tabstop with a home whose user file binds a value with an illegal byte; the editor starts, shows the first problem, and quits with status 0
- [ ] 7.2 `docs/codebase-map.md` (the new test, port methods), `docs/architecture.md` (the FilePort row), `docs/backlog.md` (remove the two fixed entries, add the ci_scope word splitting and the rename through a link), and `make gates`, `make docs-lint`
