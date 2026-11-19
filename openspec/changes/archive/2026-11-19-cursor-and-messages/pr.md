feat(frame): style the cursor line, cursor shapes, and messages

## Summary

Styles the cursor and the message line as the Facet plan draws them: the cursor line spans the whole window including the gutter, the cursor shapes are steady per mode, and messages paint their glyph, code, and text in separate groups in both themes. The editor's cursor and message row were still unstyled or painted as one bold red line, so frame rows did not match the plan.

---

## Changes

- Lift the cursor line from window column 0 to the right edge over the gutter in the focused window only, with a selection winning over it
- Paint the cursor row number bold on the cursor line, other numbers FAINT, and relative numbers FAINT with every fifth in the new LineNrFifth group
- Set steady cursor shapes: block in normal, visual and operator-pending, bar in insert, the command line and query prompts, underline in replace
- Style the command line with a DIM prompt, FG text, and DIM pending keys and match count at the right end
- Split message painting into a RED glyph with a bold RED code for errors, a YELLOW glyph for warnings, DIM info, bold BLUE more prompts, and paint the Question and MoreMsg groups
- Drop the mode indicator from the message row, since the mode pill shows the mode
- Add relativenumber to the frame geometry key so toggling it repaints both frames
- Update the screen-rendering spec, the compatibility and architecture notes, and the code map

---

## Testing

- Run the security review of the committed diff, no High or Medium findings
- Run the quality review, no blocking findings, and the benchmark review, no regressions
- Run docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, tools-test, gates, and metrics, all pass
- Run spec-validate after archiving, 54 of 54 pass

---

## Notes

The Light+ theme's DIM is its teal accent, so every fifth relative number is an accent there, a deliberate choice recorded in the design. Diagnostic virtual text, the multi-line message band, floats, and ui-groups are left to later Facet waves.
