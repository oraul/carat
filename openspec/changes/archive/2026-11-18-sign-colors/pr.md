fix(signs): draw each sign in the color of its kind

## Summary

Draws each sign in the highlight group of its kind, so an error sign is red, a warning yellow, git's added sign green, changed cyan, and deleted red, on every palette. Every sign was painted in SignColumn yellow, so the sign column showed that a row had something but not what. The host picks the group from the icon name a sign is placed with, so the plugin API is unchanged.

---

## Changes

- Fix the sign column so each sign is painted in its icon's group: error in DiagnosticError, warning in DiagnosticWarn, info in DiagnosticInfo, hint in DiagnosticHint, git_added in Added, git_changed in Changed, git_deleted in Removed, any other icon staying in SignColumn
- Add the UI groups Added, Changed, and Removed, colored green, cyan, and red in every palette, moving the syntax, file-icon, and markup groups up by three ids
- Change SignLayer and Buffer to keep a group beside each glyph, with Buffer#place_sign taking the group and the language server's diagnostic signs taking their severity's group
- Change BufferRequests#place_sign to pass Highlight.sign_group of the icon, keeping place_sign(buffer, row, icon) as it was
- Change FramePresenter to read a painted row's glyph and group from one sign layer scan, and PaintedRows to repaint a row whose sign group changed
- Refactor the severity mapping into Highlight.diagnostic_group, shared by the diagnostic sign and the painted diagnostic message, a severity outside 1 to 4 drawing as a hint
- Add frame row tests on carat-dark and carat-light for the error, warning, git added, and changed signs, with buffer, theme, plugin request, and git signs tests
- Document the sign colors in README.md, docs/compatibility.md, docs/plugins.md, docs/architecture.md, and docs/codebase-map.md, and sync the color-themes spec

---

## Testing

- Run the security review of the committed diff, pass with no high, medium, or low finding
- Run the quality review, pass with no blocking finding and one advisory recorded in docs/findings/sign-colors.md
- Run the benchmark review, pass with no blocking finding
- Run the checker stages docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, tools-test, gates, and metrics, all pass
- Run make spec-validate after the archive, all 54 items pass

---

## Notes

Plugins name highlight groups rather than numbering them, so the three-id shift of the syntax, file-icon, and markup groups breaks no plugin. The review, AI, and suggestion sign kinds of the Facet order and a group a plugin chooses itself are left out of scope. One quality advisory about the wording of task 5.2 in the archived change is recorded in docs/findings/sign-colors.md.
