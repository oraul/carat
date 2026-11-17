fix(plugins): open t and the finder's tab pick without a tree-only tab page

## Summary

The explorer's t pressed in a lone tree now opens the file in a new window beside the tree, and the finder's tab pick opens the file as the tab the top row shows, a buffer tab under option.gt buffers and a tab page under option.gt tabpages. Before, t with only the tree left opened tab page 2 and left tab page 1 holding only the tree, and the finder's pick always opened a tab page, ignoring option.gt.

---

## Changes

- Fix the explorer's t so that with no file window beside the tree it opens the file as l does, under both option.gt values, instead of a tab page that leaves the tree alone
- Fix the finder's tab pick so it opens the file through open_as_tab and follows option.gt, opening it as Enter does when no file window is left
- Add editor flows in test/editor_tab_flows.rb for t and the finder's tab pick from a lone tree under option.gt buffers and tabpages, and finder rows for the tab pick in test/editor_finder.rb, with their snapshots
- Change the file-explorer spec's requirement on splits and tab pages to state the lone-tree case, and the file-finder spec's tab pick to follow option.gt
- Document the tab opens as option.gt sets them in docs/actions.md, docs/compatibility.md, docs/plugins.md, the README, and the plugin comments
- Update the feature queue and the metrics history for this delivery

---

## Testing

- Run the security review of the committed diff, passed with no high, medium, or low findings
- Run the quality review, passed with no blocking finding and three advisories, the docs wording and spec coherence ones fixed here
- Run the checker's stages docs-lint, dev-build, test-build, diagnose, bench-budget, tools-test, test-run, gates, and metrics, all pass
- Run the benchmark review against main's recorded figures, passed
- Run make spec-validate after archiving, all 54 specs pass strict validation
- Run make gates and make docs-lint, all pass

---

## Notes

Plugins now activate on their first trigger, so the new flows reach the explorer and the finder through their first key, and every existing flow of test/editor_tab_flows.rb still passes. The quality advisory on the duplicated open_file call in the finder's tab branch is a style point and is left as it is.
