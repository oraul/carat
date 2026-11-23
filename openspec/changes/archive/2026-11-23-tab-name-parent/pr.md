feat(tabs): show the parent folder of a shared tab name

## Summary

Tabs now show the parent folder, dimmed, before a file name that another listed file tab shares, and neighbouring tabs stand two blank cells apart. Two open files such as a/x.rb and b/x.rb showed two identical tabs, and the gap was three cells where the buffer-tabs design calls for two.

---

## Changes

- Add the dimmed folder holding the file, with its slash, before a tab name while another listed file tab has the same last segment, counted by tab_width so the overflow counts stay right
- Change the tab width so a tab drops its trailing space and two tabs stand two blank cells apart
- Add Buffer parent_start beside name_start so the tab bar allocates nothing for the folder
- Remove the unread Buffer icon member and Buffer.icon_of together with their writes on every path change
- Change the buffer-tabs spec with the added and modified scenarios, and its Purpose, which no longer names icons
- Document the change in the README, the code map, and the FileIcons comment
- Update the tab-row strings and snapshots of the tab bar, buffer, definitions, frame presenter, and editor tabs tests, with new rows for a/x.rb beside b/x.rb and for the gap between two tabs

---

## Testing

- Run the fast stages at the head (docs-lint, dev-build, test-build, diagnose, bench-budget, tools-test, test-run, gates, metrics), all pass
- Run make spec-validate after the archive, all 56 items pass
- Security review of the committed diff, no findings (high 0, medium 0, low 0)
- Benchmark review, no regression against main

---

## Notes

The first-tab scenarios of the buffer-tabs spec under option.showtabline 2 still read a mark before the name; this is recorded in the findings file as outside the brief, as is the rescan of shared names for every tab width in the overflow loops.
