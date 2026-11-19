feat(finder): add a content search picker on leader fg

## Summary

Adds a content search picker to the finder, opened by plugin.finder.grep on the leader fg keys, that lists matching lines of the project's files as path, line number and text. Until now the leader ff picker matched file paths only, so a file could not be found by what it contains.

---

## Changes

- Add the plugin.finder.grep action, bound by the finder manifest to leader fg and listed in the palette, with a new Finder::Grep that reads each listed file once per open through the existing read_file host request.
- Add fuzzy ranking of lines with the existing Matcher scoring and ordering, keeping the best 200 rows and showing a count followed by a plus sign in the title when a cap cut the result short.
- Add the caps that keep the editor responsive: files over the read limit, files with a NUL byte and unreadable files are skipped, lines are cut at 400 bytes on a character boundary, and loading stops at 100000 stored lines.
- Add picks that open the file with the cursor on the line and the column of the first matched byte, with the split, vertical split and tab keys working as in the file finder.
- Add safe display of untrusted line text, with control characters shown as spaces and invalid UTF-8 bytes as question marks.
- Add the file-finder spec requirements and the test test/editor_finder_grep.rb with its snapshot, wired into the runner.
- Document the action in docs/actions.md, docs/plugins.md, README.md and the code map.
- Record the plan and the non-blocking findings for this change, and the metrics row of the previous feature-lane change, vim-folds-windows.

---

## Testing

- Run make gates, all gates pass.
- Run make test-one on test/editor_finder_grep.rb, 1 of 1 passed.
- Run make docs-lint, all checks ok.
- Security review of the committed diff recorded in the run state, with no edits since it.

---

## Notes

No new host request and no plugin API version bump. Streaming the read as a background task is left to finder-streaming and plugin-tasks, after spinel-bump, so the read is synchronous but happens once per open of the picker. Delivered in the feature lane as a user-approved exception beyond Sprint 20.
