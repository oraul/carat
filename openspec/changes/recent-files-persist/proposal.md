# Proposal

## Why

The recent files, which `<leader>fr` lists, hold the files of this run only, where Neovim's oldfiles survives a restart, and each is kept as the relative path the buffer was opened with, so after a change of the working directory the same entry names another file. The queue entry `recent-files-persist` asks for absolute paths kept in a state file read at start and written when the editor ends, through the file port, bounded as now.

This is outside the numbered roadmap of `docs/architecture.md` section 12 (all delivered); it is a Sprint 30 feature item of `docs/queue-feature.md`.

## What Changes

- Change `BufferList` to keep each recent path absolute: a new member `base`, the working directory the last file was opened in, resolves a relative path when it is noted. `OpenFile` sets it from `FilePort#cwd` at every call and the assembly at construction. With no base a path is kept as given, so a bare `BufferList` behaves as before.
- Add `BufferList#restore_recent`: appends an earlier run's paths after this run's, normalized, each once, up to `RECENT_LIMIT`.
- Add `Domain::RecentFilesText`: the state file's place (`.local/state/carat/recent_files` under the home directory), its format (one absolute path per line, most recent first), and the parse and render with the rule of a usable path (absolute, at most 4096 bytes, UTF-8, no control character).
- Add the use cases `LoadRecentFiles` (read at start, at most 1 MiB, every failure read as no paths) and `SaveRecentFiles` (write when the editor ends, creating the directories, every failure skipped), both over `FilePort`.
- Change `EditorAssembly`: `open` loads before opening the first file, and the new `close` saves; `bin/carat.rb` calls `close` in its `ensure`, so every way out of the loop writes the list.
- Change `BufferRequests#recent_files` to show each path relative to the working directory when it lies below it and absolute otherwise, so a picker row opens the file it names after a `:cd` and the finder's rows read as they did. `PluginHost` hands it the file port.
- Add tests: `test/editor_recent_files.rb` (restart over one `MemoryFiles`, the stand-in for `:cd` by moving its working directory, a missing, directory, hostile, unwritable, and no-home state, the bound, the text rules), new scenarios in `test/domain_buffer_list.rb`, and the new holders in `test/adapters_assembly.rb`.
- Document the state file in README.md, `docs/architecture.md`, and `docs/codebase-map.md`.

Assumptions: the state file is under the home directory the file port reports and never the project directory, since a file there would be input planted by an untrusted repository; the path follows the XDG state convention with no environment lookup, as the user's configuration path is fixed likewise; two editors ending at once leave the later one's list (no merge at write); a file deleted since is still listed, as oldfiles lists it.

Out of scope: showing the finder's rows with control characters made safe (`plugin-host-lows`), a `:oldfiles` command (not implemented, so no `docs/compatibility.md` row), a `:cd` command (the editor has none; the tests move the working directory of the file double), and the stale base of a buffer opened before a working directory change and shown again after a later open (recorded in the findings).

## Capabilities

### New Capabilities

### Modified Capabilities

- `buffer-list`: the recent files are absolute, kept between runs, and read as untrusted.
- `file-finder`: the recent files picker lists the earlier runs' files and shows each by the working directory.

## Impact

- Code: `carat/domain/buffer_list.rb`, `carat/domain/recent_files_text.rb`, `carat/use_cases/files/load_recent_files.rb`, `carat/use_cases/files/save_recent_files.rb`, `carat/use_cases/files/open_file.rb`, `carat/use_cases/plugins/buffer_requests.rb`, `carat/use_cases/plugins/plugin_host.rb`, `carat/adapters/editor_assembly.rb`, `bin/carat.rb`, `carat.rb`.
- Tests: `test/editor_recent_files.rb`, `test/domain_buffer_list.rb`, `test/adapters_assembly.rb`, `test/runner/run_all.rb`.
- Docs: README.md (the `fr` picker and the state file), `docs/architecture.md` (sections 5.2 and 8.3 name the use cases and the state file), `docs/codebase-map.md`.
- CLAUDE.md: unchanged, no process, agent, or workflow changed.
- docs/compatibility.md: unchanged, no Neovim command is implemented.
- docs/actions.md: unchanged, no action added.
- `carat/plugin_api.rb`: unchanged; the `Host#recent_files` comment still reads "since the editor started" and is stale, recorded in the findings, since an edit there is a plugin API edit outside this change.
- No edit of `tools/rules.sh`.
