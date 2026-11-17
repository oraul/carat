fix(buffers): close buffer tabs with :q and :bd

## Summary

Under the default `option.gt buffers`, `:q` on the last window now closes the current buffer tab while another file buffer is listed, `:bd` and the leader `bd` mapping close a buffer tab while keeping every window and the explorer, and the empty startup buffer leaves the row once a file opens in another window or tab page. A user reported that after opening a file from the explorer in a new tab the initial `[No Name]` tab could not be closed, `:q` left stale tabs in the row, and `:bd` closed windows until only the explorer was left and its toggle failed with E444.

---

## Changes

- Change `:q`, `:q!`, `:wq`, and `:x` on the last window (a file window beside only side windows counting as the last) to close the current buffer's tab when another listed file buffer exists, showing the next listed file buffer or the one before, keeping E37 for a modified buffer and quitting as before on the last listed file buffer
- Change `:bd`, `:bd N`, and the leader `bd` mapping to show the replacement buffer, or a new empty one when none is left, in every window that showed the deleted buffer instead of closing those windows, leaving side windows untouched
- Fix the startup buffer staying in the row and `:ls` after a file opens in another window or tab page, which now retires the unnamed, empty, unmodified startup buffer and shows the opened file in its window
- Fix the explorer toggle failing with E444 when the explorer is the last window, by opening a file window beside it before the scratch window closes
- Keep `option.gt tabpages` on Vim's window rules for `:q`, while no path leaves a tab page with only side windows in either mode
- Add editor tests in `test/editor_buffers.rb`, `test/editor_tabs.rb`, and `test/editor_explorer.rb` for every accepted scenario, naming each delta spec scenario, and update the snapshots of sessions that relied on the old `:q` and `:bd` rules
- Document the buffer-tab difference from Neovim in the `:q` and `:bd` rows of `docs/compatibility.md`, the README's `gt` sentence, and the codebase map entries of the touched files
- Archive the OpenSpec change and sync the `buffer-list`, `command-line-mode`, and `file-explorer` specs
- Move `merge-record-check` and `git-signs-transport` to the head of the backlog pool with `tab-close-b`, part b of this fix, as the pool's second item, and record this run's metrics row

---

## Testing

- Run the security review of the committed diff at 38a4b52a1215, passed with no High, Medium, or Low finding
- Run the checker's fast stages at 38a4b52a1215 (docs-lint, dev-build, test-build, diagnose, bench-budget, tools-test, test-run, gates, metrics), all pass
- Run the quality review, passed with no blocking finding and seven advisories
- Run the benchmark review against main's recorded figures, passed with allocations unchanged (lh 26.0, j 27.0, insert 26.0)
- Run make spec-validate after the archive, 53 of 53 items pass

---

## Notes

Part b, left for the follow-up `tab-close-b` at the front of Sprint 14 by the user's decision, covers `gt`, `gT`, `:bn`, and `:bp` with the focus in a side window and the explorer's `t` under buffer tabs. This is a counted Sprint 13 backlog item taking the slot of `merge-record-check`. The quality advisories on the E36 branch of the explorer's file window and on the per-window `lone_file_window?` check are recorded in `docs/findings/tab-close.md`.
