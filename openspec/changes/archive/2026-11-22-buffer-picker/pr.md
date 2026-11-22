feat(finder): pick open buffers and recent files, and resume the last search

## Summary

Adds three finder pickers: leader `fb` picks among the open file buffers, leader `fr` picks among the files shown since the editor started, and leader `fR` reopens the last closed search with its typed text and highlight. The finder bound only leader `ff`, leader `fg`, and Ctrl-P, so a user had no picker over open buffers or recent files and no way to get a search back, which the design council of 2026-11-21 approved adding.

---

## Changes

- Add the buffers picker on leader `fb`, listing the listed file buffers in `:ls` order under the title `Buffers N/M`, filtered and picked as the file finder is
- Add the recent files picker on leader `fr`, most recent first under the title `Recent N/M`, holding every file shown in a window this session, also after `:bd`, at most 100, a file shown again moving to the top
- Add leader `fR`, which reopens the last picker the finder closed (files, grep, buffers, or recent) with its typed text and highlight, the list read again, and shows `No search to resume` when none was closed yet
- Add the `list_buffers` and `recent_files` plugin host requests at API 2.14, each a `PluginApi::Host` method, a `PluginLink` override, and a buffer request family method
- Change the buffer list to keep the bounded recent file list as each file buffer enters a window, skipping scratch and unnamed buffers
- Add tests per key, frame snapshots of the new pickers in both carat themes and under `option.icons ascii`, and buffer list and plugin request tests
- Document the three actions in `docs/actions.md`, the File finder rows in `docs/compatibility.md`, the two requests and version history in `docs/plugins.md`, the README leader `f` paragraph, `docs/architecture.md` section 9.1 and item 12, and the code map
- Add the `file-finder` and `plugin-host` spec requirements through the archived OpenSpec change, and record the plan's queue and findings entries

---

## Testing

- Run the security review of the committed diff, pass with no High, Medium, or Low finding
- Run the quality review of the diff, one finding raised and fixed in place
- Run the check stages at the implementation head (gates, docs-lint, dev-build, test-build, test-run, diagnose, tools-test, bench-budget, metrics), all pass, confirmed by the checker
- Run the benchmark comparison against main's recorded figures, pass with no blocking difference
- Run `make spec-validate` after the archive, 56 of 56 pass

---

## Notes

Recent files are kept for the session only, so no state file is written; a list persisted across runs, as Neovim's `oldfiles`, is left for a follow-up. A resume reads its list again, so buffers closed since are gone and grep reads the files again, and the highlight returns to its row clamped to the last match. The buffer preview reads the file from the disk as the file finder's does.
