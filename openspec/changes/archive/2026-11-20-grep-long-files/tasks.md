## 1. The read bound

- [x] 1.1 Raise `FileRequests::MAX_ROWS` to 262,144 (`carat/use_cases/plugins/file_requests.rb`), move `PluginApi` to 2.10 and correct the `Host#read_file` comment (`carat/plugin_api.rb`); tests in `test/use_cases_plugin_files.rb` (read_file answers rows past the 1000th, read_file refuses more rows than the read limit holds) and the version rows of `test/editor_floats.rb`, `test/use_cases_plugins.rb`, and `test/domain_plugin_manifest.rb`

## 2. The grep picker

- [x] 2.1 Read every line of a file within the read limit (`Grep::FILE_ROWS`) in `carat/plugins/finder/grep.rb`; tests in `test/editor_finder_grep.rb` (A match past the 1000th line is found, The picker stores only bounded lines of each file)
- [x] 2.2 Keep each file's line count in `Grep` and end the preview at the file's last line (`Grep#preview`); tests in `test/editor_finder_grep_preview.rb` (The preview is clamped at the file's start and end, The preview ends at the file's last line)
- [x] 2.3 State the per-key bound in the comments of `Grep` and `Grep#search` (`carat/plugins/finder/grep.rb`); no behavior change, the existing rows of An extended query continues the search hold

## 3. The grep figure

- [x] 3.1 Add `grep` to `DEFAULT_SCENARIOS` of `tools/metrics.sh` and run its allocation runs at 20 and 120 keys there; cases in `tools/tools_test.sh` (measure records the grep scenario by default), checked by `make metrics` writing `allocs.grep`

## 4. Docs

- [x] 4.1 Update README.md, docs/plugins.md, docs/codebase-map.md, the Makefile's help lines, and the comment of the CI metrics step; make docs-lint

## 5. Review fixes

- [x] 5.1 Say in docs/plugins.md that the grep picker relies on API 2.10's `read_file` rows, dropping the no-API-change clause
- [x] 5.2 Rename the grep flag of `measure` in `tools/metrics.sh` to `with_grep`; the existing `measure records the grep scenario by default` case of `tools/tools_test.sh` holds
- [x] 5.3 Write `FileRequests::MAX_ROWS` as `READ_LIMIT` so the two cannot drift; the existing read_file rows of `test/use_cases_plugin_files.rb` hold
