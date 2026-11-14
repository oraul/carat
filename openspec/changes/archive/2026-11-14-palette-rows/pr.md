feat(palette): lay out palette rows in columns and mark matches

## Summary

The command palette now shows each row as the whole name in a 30-cell column, the description dimmed after it, and the first normal-mode key in caret notation at the right end, with the typed letters drawn where they matched; the completion popup drops its extra padding space on each side. Names of up to 29 characters lost their last letters, matches were not visible, every column was one color, and the popup stood two columns off its text.

---

## Changes

- Change the palette row layout in FollowPalette to a 30-cell name column, a dimmed description column, and a 12-cell key column at the right, aligned on every row, leaving the description out when the float is too narrow for it
- Add match marking: the palette keeps whether the name or the description scored, and draws the matched characters of the shown rows in PmenuMatch, or PmenuMatchSel on the selected row, stepping by whole characters for multibyte queries
- Add the PmenuMatch, PmenuMatchSel, PmenuExtra, and PmenuExtraSel UI highlight groups after FloatTitle and color them in every theme, the selected-row groups keeping PmenuSel contrast at each color depth
- Add FuzzyMatch.positions, the bytes the score walk matched, and KeyNotation.caret, which writes control keys in caret notation such as ^Ws
- Change the completion popup rows to drop their own leading and trailing space and move the popup one column right so labels stay under the typed word
- Add tests in editor_palette, editor_completion, domain_theme, domain_keys, and the FuzzyMatch test for the columns, caret keys, match groups, narrow floats, and multibyte matches
- Document the new groups in docs/compatibility.md, the palette row in README.md and docs/codebase-map.md, and the UI group count in docs/architecture.md, with the synced command-palette, completion, and color-themes specs and the archived OpenSpec change

---

## Testing

- Run the security review of the committed diff, pass with no High, Medium, or Low findings
- Run the quality review, pass with no blocking findings after two blocking findings were fixed, ten advisories appended to docs/backlog.md
- Run the checker stages docs-lint, dev-build, test-build, test-run, and diagnose, all pass
- Run bench-budget and metrics, pass with no regression against main's recorded figures
- Run tools-test and make gates, all pass
- Run make spec-validate after archiving, all 51 items pass

---

## Notes

The syntax, icon, and markup highlight ids move up by four to make room for the new UI groups after FloatTitle. Match spans in the completion popup and the finder, user-defined colors for the new groups, and the key hints panel are left for follow-ups. A pre-existing byte-level match in FuzzyMatch.positions inside other multibyte characters is recorded in the backlog.
