# Proposal

## Why

A project directory is untrusted input: a cloned repository chooses its `.caratrc`, its files, and the links among them. The periodic reviews at 66fd52b and 6ea61b1 found five ways such a project can stop or exhaust the editor. A `.caratrc` that is a symlink to `/dev/zero` or a FIFO makes startup exhaust memory or hang, since the gateway reads it whole after a `stat` that follows links. `option.tabstop 999999999` is accepted, and one Tab or `>>` then builds a string of that many spaces. `Keymap.action_name?` runs a regular expression on a keymap value, and under Spinel a regular expression raises on a byte that is not UTF-8, so a configuration line with such a byte stops startup (the blocking quality finding at `carat/domain/keymap.rb:42`). `OpenFile` reads a FIFO, a device, or a huge file with no type or size check, so `:e` of a FIFO hangs the editor. And the explorer's create checks containment lexically only, so a symlinked directory inside the root lets a typed name create a file outside it. Security fixes go first, so this change is outside the roadmap order; it is queue item 1 (`docs/queue.md`).

## What Changes

- The configuration parser refuses a line holding a byte outside a well-formed UTF-8 sequence, in every file (the shipped defaults, the user file, the project file) and in a plugin manifest's lines, reported as `file:line: illegal byte` and skipped; nothing after the parser sees such a byte. `Keymap.action_name?` checks the value's bytes instead of running a regular expression, so no keymap value, at load or at run time, can raise.
- The project `.caratrc` is not read when it is a symbolic link; the user and project files are not read when they are not regular files (a FIFO, a device, a socket) or hold more than 1 MiB. Each refusal is reported as `source: reason` in load order, like the existing `cannot be read`, and startup continues with the other files. A directory named `.caratrc` is still skipped silently.
- `option.tabstop` takes 1 to 9999 (Vim's limit) and `option.shiftwidth` 0 to 9999; a value outside is reported as `file:line: option.tabstop takes a number from 1 to 9999` and the earlier value is kept.
- `:e` and every other open (startup, splits, tab pages, the plugin `open` request) refuse a directory with `"path" is a directory`, a FIFO, device, or socket with `"path" is not a file`, both as Vim words them, and a file larger than 64 MiB with `E484: Can't open file path: File too large`; the current buffer stays. The file is opened without blocking and read through a bounded read, so even a path swapped for a FIFO after the check cannot hang the editor.
- A plugin's create request (the explorer's `a`) is refused with `Outside the tree root: path` when the parent directory, with every symbolic link resolved, is not the root or inside it, so a link inside the tree that leads outside it cannot be created through. A link that stays inside the root still works.
- The file port gains a bounded `read(path, limit)` that reads only a regular file, a `regular` flag in `PathInfo`, and `real_path(path)`; the disk driver opens files with `O_NONBLOCK` and checks the opened file, and the memory double models links with targets and special files.
- `docs/backlog.md`: the two entries this change fixes (the project `.caratrc` type and size, tabstop and shiftwidth) are removed; the CI scope script's word splitting (`tools/ci_scope.sh:66`, Low, periodic security review at 6ea61b1) is recorded for pipeline-hardening, queue item 2; rename through a symlinked directory is recorded as a follow-up.

Out of scope: a rename or delete through a symbolic link (recorded in the backlog), refusing a symlinked user file (dotfile managers link it), a race in which the project directory is changed between the check and the open (the open itself cannot hang and reads at most the cap, which bounds the harm), bounds on the other integer options, a configurable size limit, and the ci_scope fix itself, which is pipeline-hardening's.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `config-files`: illegal bytes, non-regular, symlinked, and oversized files are refused with a report; tabstop and shiftwidth are bounded.
- `keymap-config`: a keymap value with an illegal byte is reported, never a crash.
- `command-line-mode`: `:e` refuses a directory, a non-regular file, and a file above the size limit.
- `plugin-host`: a create request through a symbolic link that leaves the root is refused.

## Impact

- Code: `carat/domain/rc_parser.rb`, `carat/domain/keymap.rb`, `carat/domain/options.rb`, `carat/domain/config.rb`, `carat/domain/path_info.rb`, `carat/ports/file_port.rb`, `carat/drivers/disk_files.rb`, `carat/doubles/memory_files.rb`, `carat/adapters/rc_config_gateway.rb`, `carat/use_cases/files/open_file.rb`, `carat/use_cases/files/make_path.rb`.
- Tests: rows with hostile inputs in `test/domain_rc_parser.rb`, `test/domain_keymap.rb`, `test/domain_options_config.rb`, `test/adapters_config_gateway.rb`, `test/editor_cmdline.rb`, `test/use_cases_plugin_files.rb`; a new `test/drivers_disk_files.rb` over a real directory (a symlink to `/dev/zero`, a FIFO, a file above the limit, a symlinked parent); a hostile project and home in `test/smoke_editor.rb`.
- Docs: `docs/codebase-map.md`, `docs/architecture.md` (the FilePort row), `docs/backlog.md`, `docs/compatibility.md` (the `:e` refusals).
- No new dependency. Allocations per key stay at the baseline: the one change on the key path, `Keymap.action_name?` in `HandleKey`, replaces a regular expression by a byte loop that allocates nothing.

Assumptions recorded here:

- A refused file is reported as `source: reason` with no line number, the form `cannot be read` already uses, rather than a line 0 the backlog outline suggested.
- The limits are 1 MiB for a configuration file and 64 MiB for a file opened in a buffer, constants rather than options.
- A line whose comment holds an illegal byte is refused too, as a control character in a comment already is.
- Containment is checked on the parent's real path because the target does not exist yet; the root is resolved too, so a root that is itself a link keeps working.
