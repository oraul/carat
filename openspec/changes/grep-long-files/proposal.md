## Why

The grep picker (`<leader>fg`) searches only the first 1000 lines of each file, because the host's `read_file` refuses more rows, so the user could not find a line further down a long file (four files of this tree are longer); its preview also stops at the last non-empty line it stored instead of the file's end, the comment on its per-key budget claims a bound the narrowing search does not keep, and `make metrics` records no figure for the grep scenario, so a rise in its allocations per key (644.6 to 842.6 at -O 0 when the preview float came) went unnoticed. Outside the roadmap of `docs/architecture.md` section 12: a T2 user request on the finder plugin (Sprint 22 item 1).

## What Changes

- `read_file(path, rows)` accepts up to 262,144 rows, as many lines as a file within its 256 KiB read limit can hold, where it refused more than 1000; the plugin API's minor version becomes 2.10, so a plugin that asks for more rows is refused by an older host rather than failing on each read.
- The grep picker reads every line of a file within the read limit (`Grep::FILE_ROWS` 262,144), so a match on line 1500 of a 2000-line file is listed and its pick opens at that line; the 400,000-line store cap, the 400-byte cut, and the 30,000-line per-key budget are unchanged.
- The grep preview ends at the file's last line, the empty lines at its end included, where it ended at the last stored (non-empty) line.
- The comments on the per-key budget in `Grep` state the bound the search keeps: the last key's matches checked again, then new lines within `LINE_BUDGET` less those kept, so at most twice `LINE_BUDGET` line checks a key.
- `make metrics` measures the `grep` scenario among its default scenarios, so `metrics-compare` compares `allocs.grep` with main's; `bench/run.sh` runs `grep`'s allocation runs at a tenth of the keys of the others (20 and 120 by default), since a grep key takes milliseconds, which `make bench-budget` passed as variables before.
- Out of scope, queued apart (finder-path-safe): the file finder's raw paths in rows and the preview title, the other invisible format code points `Grep#safe` passes, one sanitizer for both pickers, and a pick into a modified buffer.

## Capabilities

### New Capabilities

### Modified Capabilities
- `plugin-host`: `read_file` accepts up to 262,144 rows.
- `file-finder`: the grep picker stores every line of a file within the read limit, and its preview ends at the file's last line.

## Impact

- Code: `carat/plugin_api.rb` (`MINOR`, `VERSION`, the `read_file` comment), `carat/use_cases/plugins/file_requests.rb` (`MAX_ROWS`), `carat/plugins/finder/grep.rb` (`FILE_ROWS`, the file line counts, `preview`, the budget comments), `bench/run.sh`, `tools/metrics.sh`, the Makefile's `bench-budget` and `metrics` lines, the comment of `.github/workflows/ci.yml`'s metrics step.
- Tests: `test/use_cases_plugin_files.rb`, `test/editor_finder_grep.rb`, `test/editor_finder_grep_preview.rb`, the version rows of `test/editor_floats.rb`, `test/use_cases_plugins.rb`, and `test/domain_plugin_manifest.rb`, and their snapshots.
- API: minor version 2.10; additive, a 2.9 plugin keeps working.
- Memory: one integer per stored file (its line count); the store cap still bounds the lines stored.
- README.md: changed, the grep picker's bounds.
- docs/plugins.md: changed, the version list, the `read_file` row, and the grep section.
- docs/codebase-map.md: changed, the plugin API, file requests, grep, metrics, and bench lines.
- docs/architecture.md: unchanged, it names no `read_file` bound and no API version, and no layer or port changes.
- docs/compatibility.md, docs/actions.md: unchanged, no Neovim command and no action is added or changed.
- CLAUDE.md: unchanged, the Makefile and CI edits change which scenarios `make metrics` measures, not the process or a command.
