## Context

`Grep` keeps each listed file's non-empty lines in one run of `@texts` (cut at 400 bytes), their 1-based line numbers in `@numbers`, and the file of each in `@file_of`; empty lines are not stored, only the first 1000 lines of a file are read, and a file's total length is not kept. The file finder's preview reads the first `height` lines of the highlighted file on every refresh; `refresh` closes and opens both floats on every key and move.

## Goals / Non-Goals

**Goals:**
- The file finder's preview for the grep picker, around the matched line, with no file read per key.
- Safe text, and no more allocations of a key than before on the existing scenarios.

**Non-Goals:**
- A host float style for the matched line; a change of the file finder's preview.

## Decisions

- The window is computed in `Grep#preview(row, height, mark, other)` from the stored lines: the top line number is the matched number less `height / 2`, then at most the last stored line number less `height - 1`, then at least 1. The preview ends at the file's last stored line, since the store keeps neither a file's length nor its trailing empty lines (a window near the end therefore ends at the last non-empty line within the first 1000). The walk starts at the row's stored index and steps back while the previous stored number is at least the top, so it costs at most `height` steps with no allocation but the output.
- Where a line number is missing from the run, the line was empty (or past the last stored line, ending the window): it shows as an empty string.
- A new `@starts` array holds the index in `@texts` where each file's run starts (pushed in `add_file` beside `@files`); a file's run ends where the next file's starts, or at the end of the texts. One integer per file; the alternative, scanning for the file's edges per refresh, costs up to 1000 steps per key.
- The match mark is the text prefix `> ` the list uses for its highlighted row (the file finder's selection is that prefix, not a style): no new colour and no host request. The other lines take the list's two-space prefix, so the preview columns line up.
- `plugin.rb` keeps one `refresh`: the gate loses `!@grep`, and the preview rows come from a private `preview_lines`, the stored window for a grep and the read file for the finder. The grep preview's title is `Grep#shown_path`, the path through `safe`.
- `safe` returns a printable ASCII text as it is (a byte scan, no allocation): the second float adds up to 18 lines a key, and the lines and rows of ordinary source are plain, so no copy is made for them.

## Risks / Trade-offs

- A preview near a file's end ends at the last stored line, not at the file's true end, and a file past 1000 lines previews only its first 1000; the picker already searches no more.
- A line shows cut at 400 bytes, as the row does.
- The `grep` bench scenario runs at 200 columns, so it now builds and draws the preview float each key: at -O 0 its allocations per key rose from 644.6 to 842.6 and its time per key from 23.7 to 24.7 ms, mostly the second float's host copies and render, about 20 allocations being the preview's own lines. Recorded in the change's findings, not reduced here.
