feat(finder): preview the matched file in the grep picker

## Summary

The content search picker now shows the same preview float as the file finder on a terminal of 100 columns or more, centred on the highlighted row's matched line. The user asked for it because the grep picker listed lines but never showed the file around them.

The preview is built from the text the picker stored when it opened, so no file is read per key or per move, and it goes through the same safe-text path as the rows.

---

## Changes

- Add the grep preview float beside the grep list on a terminal of 100 columns or more, titled with the highlighted row's path, with the file finder's layout and sizing
- Add a window of lines with the matched line in the middle, clamped at the file's start and end, the matched line carrying the list's highlight mark and no new style or colour
- Change the preview to follow the highlighted row and the query, and to close on an empty result or an empty query, with none on a terminal under 100 columns as before
- Change the grep list to be sized as the file finder's list beside its preview where it used the whole width before
- Change Grep#safe to return printable ASCII text as it is, so a plain row or preview line costs no copy and a key allocates no more than before
- Document the grep preview in README.md, docs/plugins.md, and the finder area of docs/codebase-map.md, and sync the file-finder spec through the archived change
- Add test/editor_finder_grep_preview.rb with its snapshot, and update two rows of test/editor_finder_grep.rb

---

## Testing

- Run the security review of the committed diff, pass with no blocking finding, the one Low finding of confidence 5 recorded in the findings file
- Run the quality review of the committed diff, pass with no blocking finding
- Run the benchmark review, pass with the allocations per key held and the grep time per key not regressed
- Run the checker stages docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, tools-test, gates, and metrics, all exit 0
- Run make gates and make docs-lint on the package commit, both pass
- Run make spec-validate after the archive, 54 passed, 0 failed

---

## Notes

The file finder's rows and preview title still show the listed path unsanitized while the grep path now goes through Grep#safe; this predates the change and is recorded in the findings file as a follow-up. No host request is added and the API version is unchanged.
