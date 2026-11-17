fix(explorer): move the file window's buffer tab from a side window

## Summary

Makes the top row's tabs behave from the explorer: with the focus in a side window, gt, gT, :bn, :bp, and the other buffer switches move the file window's buffer tab and keep the explorer, the explorer's t opens a buffer tab under option.gt buffers, and :tabe of a listed file leaves no empty buffer behind. These are the parts of the user's tab report left after #178, where a switch from the explorer replaced the explorer's own buffer or turned it into a second [No Name] window, and t opened a Vim tab page while the row showed buffer tabs.

---

## Changes

- Fix every buffer switch through SwitchBuffer run from a side window to act on the tab page's file window (the previous window when it shows a file, else the first file window) and focus it, the side window keeping its buffer, with the message "No file window to show the buffer in" when there is none.
- Add the plugin host request open_as_tab, plugin API 2.8, which opens a file in the editing window as a buffer tab under option.gt buffers and as a tab page under option.gt tabpages or with no file window.
- Change the explorer's t to call open_as_tab, so under option.gt buffers the file opens in the file window as a new buffer tab with the focus in it and the explorer kept, a listed file showing its existing tab.
- Fix :tabe and :tabedit of an already listed file to show that buffer in the new tab page and leave no empty [No Name] buffer listed, :tabe with no name still opening an empty buffer.
- Add TabPage#editing_leaf, shared by SwitchBuffer and the explorer's editing_window, so both pick the same file window.
- Add test/editor_tab_flows.rb, 18 flows typed through EditorHarness with the explorer on and started as carat . does, asserting the top row, current buffer, listed buffers, window and tab page counts, the explorer, the message, and quit after every step, including the user's reported sequences and the tab-page flows.
- Add rows to test/editor_explorer.rb and test/editor_buffers.rb for gt, gT, :bn, and :bp from the explorer, t under both option.gt values, and :tabe of a listed file, and bump the plugin API version rows.
- Document the behavior in README.md, docs/plugins.md, docs/actions.md, docs/compatibility.md, and docs/codebase-map.md, and sync the buffer-list, file-explorer, plugin-windows, and tab-pages specs through the archived OpenSpec change.
- Record the plan, the metrics history, and two review findings, and take tab-close-b out of the Sprint 14 queue.

---

## Testing

- Run the security review of the committed diff, pass with no High, Medium, or Low finding.
- Run the quality review, pass with no blocking finding and 3 advisories, 2 recorded in docs/findings/tab-close-b.md and the third, a style note on open_as_tab building a WindowResponse to read its id, dropped.
- Run the checker's stages docs-lint, dev-build, test-build, diagnose, bench-budget, tools-test, test-run, gates, and metrics, all pass.
- Run the benchmark review against main's recorded figures, pass.
- Run make spec-validate after the archive, 53 passed and 0 failed.

---

## Notes

The finder's Ctrl-T keeps opening a tab page under both option.gt values, since the user's decision named the explorer's t; :bd, :q, and the window commands from a side window keep the rules of #178. Plugins asking for a tab page through open_in_tab keep getting one; open_as_tab is a new request so no existing plugin changes behavior.
