## 1. The read bound

- [ ] 1.1 Raise `FileRequests::MAX_ROWS` to 262,144 (`carat/use_cases/plugins/file_requests.rb`), move `PluginApi` to 2.10 and correct the `Host#read_file` comment (`carat/plugin_api.rb`); tests in `test/use_cases_plugin_files.rb` (read_file answers rows past the 1000th, read_file refuses more rows than the read limit holds) and the version rows of `test/editor_floats.rb`, `test/use_cases_plugins.rb`, and `test/domain_plugin_manifest.rb`

## 2. The grep picker

- [ ] 2.1 Read every line of a file within the read limit (`Grep::FILE_ROWS`) in `carat/plugins/finder/grep.rb`; tests in `test/editor_finder_grep.rb` (A match past the 1000th line is found, The picker stores only bounded lines of each file)
- [ ] 2.2 Keep each file's line count in `Grep` and end the preview at the file's last line (`Grep#preview`); tests in `test/editor_finder_grep_preview.rb` (The preview is clamped at the file's start and end, The preview ends at the file's last line)
- [ ] 2.3 State the per-key bound in the comments of `Grep` and `Grep#search` (`carat/plugins/finder/grep.rb`); no behavior change, the existing rows of An extended query continues the search hold

## 3. The grep figure

- [ ] 3.1 Run `grep`'s allocation runs at a tenth of the keys in `bench/run.sh`, drop the variables from `make bench-budget`, and add `grep` to `DEFAULT_SCENARIOS` of `tools/metrics.sh`; checked by `make bench-budget` and `make metrics` writing `allocs.grep`

## 4. Docs

- [ ] 4.1 Update README.md, docs/plugins.md, docs/codebase-map.md, the Makefile's help lines, and the comment of the CI metrics step; make docs-lint
