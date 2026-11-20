feat(plugins): let a plugin style its float's selected row and spans

## Summary

Adds the plugin host request style_float at API 2.12, which draws a selected row of a plugin's float in PmenuSel and match spans on it in PmenuMatch, as the editor's own palette is drawn. A plugin float could not be styled before, since no request set a selected row or spans and no group id under 65 was admitted, so the finder had to mark its row with a text prefix.

---

## Changes

- Add style_float(window, selected, spans) as a PluginApi::Host method, a PluginLink override, and a WindowRequests method, replacing the float's previous style and clearing it on an empty one, with no new FloatOptions member
- Admit PmenuSel and PmenuMatch as float span groups beside the syntax, file-icon, and markup groups, refusing every other id under 65 with "No float group N", while a tokenizer's token in either group is still dropped
- Refuse a missing float, a selected or span row outside the float's lines, a span list whose length is not a multiple of four, and a negative column or a length below one, each leaving the float unchanged
- Change set_float_lines to drop the float's style on a refill, and add the float's style count to the frame presenter's float key so a restyle with unchanged lines repaints
- Bump PluginApi to 2.12 so a manifest written against 2.0 to 2.11 still loads and 2.13 is refused
- Add tests in test/editor_floats.rb for a styled row and spans, the refusals, the refill, and the repaint, one in test/use_cases_plugins.rb for a disabled plugin's link, and update the theme, manifest, syntax, and plugin tests for the new version and groups
- Document the request, syntax_group's two new names, and the version history in docs/plugins.md and the code map, and sync the plugin-host spec

---

## Testing

- Run the security review of the committed diff, pass with no high, medium, or low finding
- Run the quality review, pass with no blocking finding and one advisory recorded in docs/findings/picker-styles-b.md
- Run the checker's stages docs-lint, dev-build, test-build, diagnose, bench-budget, tools-test, test-run, gates, and metrics, all pass
- Run the benchmark review against main's recorded figures, pass with no blocking finding
- Run make spec-validate after the archive, 54 passed and 0 failed
- Run make gates and make docs-lint before the push, both pass

---

## Notes

The finder still draws its rows with the text prefix; switching it to style_float is the separate finder-rows queue item, and this change edits no plugin. A token span on a float's selected row is painted on the float layer, so a group without its own background shows NormalFloat inside the PmenuSel bar; that advisory is recorded in docs/findings/picker-styles-b.md for a follow-up.
