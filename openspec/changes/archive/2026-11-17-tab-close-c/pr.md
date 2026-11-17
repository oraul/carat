fix(buffers): switch the focused reading view and keep the previous window

## Summary

Makes `:bn`, `:bp`, `:b N`, Ctrl-^, and gt act on the focused window in a reading view, alone or beside a split, and makes a refused buffer switch change nothing. Since tab-close-b, any window on a scratch buffer counted as a side window, so a lone reading view failed with "No file window to show the buffer in", a split reading view switched the other window, and a refused switch from a side window moved the tab page's previous window. A side window is now known by what it is, a sidebar or panel slot window showing a plugin's view, rather than by its buffer being scratch.

---

## Changes

- Add `TabPage#side_window?`, true only for a window of the sidebar or panel slot that shows its plugin's view
- Change `SwitchBuffer` to send a switch from a side window to the editing window only when `side_window?` holds, so a reading view or a pinned documentation split switches itself
- Fix `SwitchBuffer` so a switch refused after focusing the editing window restores both the current and the previous window of the tab page
- Add flows to `test/editor_tab_flows.rb` typing the five commands from a lone and from a split reading view, and a refused switch from the explorer followed by Ctrl-W p, with `side_window?` rows in `test/editor_breadcrumbs.rb`
- Change the buffer-list spec's side-window switch rule to name what a side window is and to keep the previous window on a refusal
- Document the rule in the README, the `:bnext` row of `docs/compatibility.md`, and the `tab_page.rb` and `switch_buffer.rb` entries of `docs/codebase-map.md`
- Record two non-blocking review findings in `docs/findings/tab-close-c.md` and apply the feature-lane plan to `docs/queue-feature.md`

---

## Testing

- Run the security review of the committed diff, pass with 0 high, 0 medium, and 0 low findings
- Run the quality review, pass with 0 blocking findings and 3 advisories
- Run the checker's fast stages (docs-lint, dev-build, test-build, diagnose, bench-budget, tools-test, test-run, gates, metrics), all pass
- Run the benchmark review against main's recorded figures, pass
- Run `make spec-validate` after archiving, 53 passed and 0 failed

---

## Notes

Fixes the tab bug the user reported, part c of tab-close (178, 181); every earlier flow of `test/editor_tab_flows.rb` still passes. Out of scope: `Quit` and `TabPage#file_window_count` keep their scratch-based notion of a side window, and with the explorer beside a lone reading view a switch from the explorer is still refused, as the existing requirement says; both are recorded as follow-ups. A review advisory to move the `side_window?` assertions from the breadcrumbs test to `test/domain_slot.rb` is dropped as a style point.
