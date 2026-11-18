feat(themes): give indent guides their own colors and a solid scope guide

## Summary

Gives the indent guides palette colors of their own, quiet in carat-dark and carat-light, and draws the guide of the block holding the cursor as a solid │ while the other guides keep ┊. The guides were painted in the FAINT and DIM text roles and were all the same dotted glyph, so they competed with the code they frame and the cursor's block stood out only by a color close to the comment color.

---

## Changes

- Add the palette roles GUIDE and GUIDE_SCOPE to every palette and color IblIndent and IblScope with them: carat-dark #30364b and #46506e, carat-light #d8dce8 and #a9b4d6, both index 8 at 16 colors, the four other palettes keeping their guides' current colors.
- Change the contrast rule for carat-dark and carat-light so IblIndent is fainter than IblScope, which is fainter than Comment, on the background and the cursor line at 24-bit and 256 colors, with a 1.1:1 floor in place of the 3:1 decoration floor, which the other four palettes keep.
- Draw the cursor's block guide with the fixed code point Options::SCOPE_GUIDE, a solid │, or | with the ascii icon set, and fold the fallback into the IndentGuides stamp so switching icon sets repaints the scope column.
- Add rows to test/domain_theme.rb ordering guide, scope, and Comment on carat-dark and carat-light and checking the other palettes' guides keep 3:1, frame rows to test/adapters_indent_guides.rb showing │ on the scope column and ┊ on the others, and a scope code row to test/domain_options_config.rb.
- Document the guide colors and the solid scope guide in docs/compatibility.md, the README option line, and the codebase map.
- Update the color-themes and indent-guides specs and archive the guide-colors change.

---

## Testing

- Run the security review of the committed diff, pass with no high, medium, or low finding.
- Run the quality review, pass with no blocking finding; its four advisory findings were fixed in place and re-reviewed.
- Run the checker's stages docs-lint, dev-build, test-build, diagnose, bench-budget, tools-test, test-run, gates, and metrics, all pass.
- Run the benchmark comparison against main's recorded figures, pass.
- Run make spec-validate after the archive, all 54 items pass.

---

## Notes

Delivers Facet wave 1 item 1 of the feature queue. At 16 colors both guides share index 8, so the scope guide is told apart there by its solid glyph only. The scope glyph is fixed rather than an option, and one_dark, one_light, dark_plus, and light_plus keep their current guide colors; new colors for them are left out of scope.
