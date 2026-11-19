feat(screen): style the command line and the message row

## Summary

Styles the command line and the message row with the Facet groups: the prompt and the pending keys are dim, an error draws a red glyph and a bold red code, and the hit-enter prompt is painted. This covers the command-line and error-message styling of parts 4 and 5 of the cursor and messages styling plan, and leaves the match count, the warning glyph, and the More pager to later changes, since no code produces them yet.

---

## Changes

- Draw an error message as a DiagnosticError glyph, an ErrorMsg code, and Normal text instead of one MESSAGE_ERROR line, with the glyph taken from the error icon of the icons option.
- Draw the command line prompt and the pending keys at the right of the message row in a new dim MsgDim group, and any non-error message in MsgDim, leaving the typed text as Normal.
- Paint the hit-enter prompt with Question.
- Leave the message row blank in insert mode, since the status bar pill shows the mode.
- Change the WarningMsg and MoreMsg theme rows for every palette and add the MsgDim row, moving the later highlight ids up by one.
- Update the screen-rendering, insert-mode, and color-themes specs, docs/compatibility.md, the architecture Highlight paragraph, the code map, and the README for the new styling.
- Add frame presenter and theme tests for each group in carat-dark and carat-light and under NO_COLOR, and update the tests that read an error from the message row.

---

## Testing

- Run the security review of the committed diff, pass with no high, medium, or low findings
- Run the quality review of the committed diff, pass with no blocking findings
- Run the benchmark review, pass with no blocking findings
- Run the checker stages docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, tools-test, and gates, all pass
- Run make spec-validate after archiving, all 54 items pass
- Run make gates and the pull request body gate after rewriting this text, both pass

---

## Notes

The warning glyph, the More pager, and the match count have no producer yet, so their theme rows are changed or added but painted by no code, and the earlier pull request 223 stays only partly true until those land; the multi-line message band, the diagnostic text, and ui-groups are left out as the brief says.
