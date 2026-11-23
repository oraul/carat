feat(recent-files): keep the recent files between runs as absolute paths

## Summary

Keeps the recent files between editor runs, so the recent files picker lists the earlier files after a restart, and keeps each as an absolute path so a change of the working directory does not make an entry name another file. Until now the list held this run's files only, as the relative paths the buffers were opened with.

---

## Changes

- Add a state file under the home directory, read at start and written when the editor ends through the file port, bounded by the existing recent limit, with a missing, unreadable, oversized, or hostile file read as empty
- Add `Domain::RecentFilesText`, which defines the state file's place and its format of one absolute path per line and parses and renders it, refusing a path that is relative, too long, not UTF-8, or holding a control character
- Change `BufferList` to keep each recent path absolute, resolved against the working directory the file was opened in, and add `restore_recent` to append an earlier run's paths after this run's
- Change `EditorAssembly` to load the list before the first file opens and to save it in a new `close`, which `bin/carat.rb` calls in its `ensure` so every way out of the loop writes it
- Change `BufferRequests#recent_files` to show a path relative to the working directory when it lies below it and absolute otherwise, so a picker row opens the file it names after a directory change
- Change the file port, its disk driver, and `MemoryFiles` so the state file is written privately without following a link
- Add tests in `test/editor_recent_files.rb`, `test/domain_buffer_list.rb`, and `test/drivers_disk_files.rb` for a restart over one `MemoryFiles`, the working directory moved, and the bound and the hostile and unwritable states
- Document the state file in README.md, `docs/architecture.md`, and `docs/codebase-map.md`, and sync the `buffer-list` and `file-finder` specs through the archived change

---

## Testing

- Run the security review of the committed diff, no finding at any severity
- Run the fast stages through the change check at the reviewed head: docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, tools-test, gates, and metrics all pass
- Run `make spec-validate` after the archive, 56 specs pass

---

## Notes

The state file lives under the home directory and never the project directory, since a file there would be input planted by an untrusted repository. Two editors ending at once leave the later one's list, and a file deleted since is still listed, as Neovim's oldfiles does. Out of scope and recorded as findings: the stale `Host#recent_files` comment in the plugin API, safe display of control characters in the finder's rows, and the base of a buffer opened before a directory change.
