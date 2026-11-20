## Context

The grep picker reads each listed file once through the host's `read_file(path, rows)` with `FILE_ROWS` 1000, the most rows `FileRequests` accepts (`MAX_ROWS`); the read itself is bounded by `READ_LIMIT`, 256 KiB. The preview of a row ends at the number of the file's last stored line, and the store skips empty lines. `tools/metrics.sh` measures eight scenarios, not `grep`, which `make bench-budget` runs with `BENCH_SMALL=20 BENCH_LARGE=120` and prints only.

## Goals / Non-Goals

**Goals:** a match anywhere in a file within the read limit is found; the preview reaches the file's end; the budget comment is true; the grep scenario's allocations per key are recorded and compared.

**Non-Goals:** streaming or chunked reads, a larger read limit, the path sanitizer of both pickers, and the pick into a modified buffer (queued as finder-path-safe).

## Decisions

- Raise `read_file`'s row bound to `READ_LIMIT` (262,144) rather than add a request: a file within the byte limit holds at most that many lines (one byte each), so the row bound no longer cuts a file the byte limit admits, the response is still bounded by the 256 KiB read, and no new `Host` method, `PluginLink` override, or family method is needed. The minor version moves to 2.10 because a plugin relying on the wider bound must be refused by a 2.9 host; existing callers (the finder's preview by its height, git signs by one row) are unchanged.
- `Grep::FILE_ROWS` becomes 262,144, the plugin's own copy of the bound, since a plugin names no host constant. The store cap of 400,000 lines still ends loading, so memory stays bounded.
- `Grep` keeps each file's line count (`@ends`): the length of the read's lines, or the lines up to the one the store cap stopped at. `preview` clamps the window to it, so the empty lines at a file's end show, as the empty lines inside it already do.
- The per-key budget keeps its behavior (the spec's "within 30,000 lines less those it kept", which lets a narrowing query move on at once); only the comments change, to name the bound of twice `LINE_BUDGET` line checks. Counting the rechecked lines against the budget instead would stall a narrowing key whose last result filled it.
- `tools/metrics.sh` runs `grep` apart from the other scenarios, with `BENCH_SMALL=20 BENCH_LARGE=120` as `make bench-budget` does: both are multiples of the scenario's ten-key cycle, so the figure is exact and equals the one `make bench-budget` prints. Keeping the counts in `bench/run.sh` instead would leave them untested, since `tools-test` may read only the paths `TOOLS_RE` of `tools/rules.sh` covers, and this change leaves that file alone. `grep` joins `DEFAULT_SCENARIOS`; `metrics-compare` reports it as new until main records it.

## Risks / Trade-offs

- A tree with many long files now stores more lines on open: the 400,000-line cap and the 256 KiB read limit bound it, and the bench corpus (150 files of 1000 lines) is unchanged.
- `make metrics` runs longer by the grep scenario (two runs over 150,000 lines at 20 and 120 keys, and the timed run), about what `make bench-budget` already spends on it.
