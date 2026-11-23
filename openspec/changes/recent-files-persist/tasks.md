# Tasks

## 1. The list keeps absolute paths

- [x] 1.1 Add `BufferList#base` and `restore_recent`, and resolve a noted path against the base (`carat/domain/buffer_list.rb`); proved by `test/domain_buffer_list.rb`, scenarios "The recent files keep absolute paths" and "The recent files take the paths an earlier run kept"
- [x] 1.2 Set the base in `OpenFile` and the assembly (`carat/use_cases/files/open_file.rb`, `carat/adapters/editor_assembly.rb`); proved by `test/editor_recent_files.rb`, the working directory change scenarios

## 2. The state file

- [x] 2.1 Add `Domain::RecentFilesText` (`carat/domain/recent_files_text.rb`); proved by the text rows of `test/editor_recent_files.rb`
- [x] 2.2 Add `restore_recent_files` and `save_recent_files` to `EditorAssembly`, run by `open` and `close`, and call `close` in `bin/carat.rb`; proved by `test/editor_recent_files.rb` (restart, missing, directory, hostile, no home, unwritable, bound) and `test/adapters_assembly.rb`

## 3. The picker

- [x] 3.1 Show each recent path by the working directory in `BufferRequests#recent_files` (`carat/use_cases/plugins/buffer_requests.rb`, `plugin_host.rb`); proved by `test/editor_recent_files.rb`, scenarios "The recent files keep naming their files after the working directory changes" and "A path inside the working directory is shown relative", and the unchanged rows of `test/editor_finder.rb`

## 4. Docs

- [x] 4.1 Update README.md, `docs/architecture.md`, and `docs/codebase-map.md`

## Quality review

- [x] 5.1 `restore_recent_files` asked the port to `stat` the path before the `read`, which already raises for a missing file; drop the extra port call (`carat/adapters/editor_assembly.rb`), fixed, proved by the missing-file rows of `test/editor_recent_files.rb`
- [x] 5.2 The `Host#recent_files` comment in `carat/plugin_api.rb` still says since the editor started; a plugin API edit is outside this change, recorded in `docs/findings/recent-files-persist.md`
- [x] 5.3 A buffer opened before a working directory change resolves against a later base; the editor has no `:cd`, recorded in `docs/findings/recent-files-persist.md`
- [x] 5.4 The state file is written through a link and without a lock; a convenience list in the user's own home, recorded in `docs/findings/recent-files-persist.md`
