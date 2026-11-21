feat(tabs): show only the modified mark on tabs

## Summary

Removes the gem from the selected buffer tab so tabs show only the modified mark, as the user decided. The selected tab is now told apart by its accent background and bold, and the ascii gem that shared the `*` character with the ascii modified mark is gone.

---

## Changes

- Remove the gem from `TabBar`: the leading cell of every tab is a space, so tab widths and the overflow arithmetic are unchanged, and `GEM` and `ASCII_GEM` are deleted.
- Change the buffer-tabs spec requirement "A tab per listed file buffer" to say the selected tab carries no gem and is told apart by the selected-tab group.
- Change the tab-flow test to compare row 0 as squeezed text, dropping `strip_tab_cells`, `counter_end`, and `tab_boundary?` and about 60 lines of heuristics.
- Change the tab bar, frame presenter, definitions, and editor tab tests and their snapshots to assert frame rows without a gem.
- Document the change in the README, `docs/compatibility.md`, and the code map.
- Record the remaining advisories in the findings file and apply the planned queue.

---

## Testing

- Run the security review of the committed diff, no findings at any severity
- Run the quality review, no blocking findings and three advisories, recorded in the findings file
- Run the checker stages docs-lint, dev-build, test-build, diagnose, bench-budget, tools-test, test-run, gates, and metrics, all exit 0
- Run the metrics comparison, allocations for the lh scenario held at 25

---

## Notes

None.
