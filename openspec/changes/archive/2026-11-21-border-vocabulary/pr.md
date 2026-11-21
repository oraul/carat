feat(plugins): let a plugin choose its float's border style

## Summary

Adds a plugin host request, set_float_border, at plugin API 2.13 that gives one of a plugin's floats its own border style: none, single, double, rounded, or solid, Neovim's names, or an empty name to go back to option.winborder. Until now a plugin float's border was a single bool drawn in the user's global option.winborder, so a plugin could not pick a named style for its own float the way a Neovim plugin can. FloatOptions has required members, so a new member would need a major version; the style is a separate request instead, and a 2.12 plugin's border bool is still honored.

---

## Changes

- Add PluginApi::Host#set_float_border, its PluginLink override, and the WindowRequests method, which refuses another plugin's float or an unknown id with "No float N" and an unknown name with the list of styles, changing nothing on a refusal
- Draw a styled float's edge in its own glyphs, ASCII under option.icons ascii and NO_COLOR, still in FloatBorder with the title in FloatTitle, and place it with its own style's edge width
- Add FloatWindow#border_style and style_under, and FloatSpec#bordered, so a styled float is bordered whatever its FloatOptions said, and raise the float's style count so a restyle that keeps the box repaints
- Bump PluginApi to 2.13; a manifest written against 2.0 to 2.12 still loads, its floats bordered by the bool as before
- Add tests for each style's frame rows and their ASCII forms, a plugin requesting a style, the refusals, the current window and a switched float keeping its style, and a 2.12 manifest loading
- Document the request, the version history, and api_version in docs/plugins.md, and the touched files in the code map
- Sync the plugin-host spec with two added and two modified requirements, and archive the OpenSpec change

---

## Testing

- Run the security review of the committed diff, pass with no findings
- Run the quality review of the committed diff, pass with no blocking finding; its one advisory, a highlight assertion that checked the last loop row's editor, is fixed in place with its own float
- Run the benchmark review, pass with no blocking finding
- Run the checker stages docs-lint, dev-build, test-build, diagnose, bench-budget, tools-test, test-run, gates, and metrics, all pass
- Run make spec-validate after the archive, 55 passed and 0 failed

---

## Notes

The split separators and the editor's own floats keep the global option.winborder and are left for the queued separator-styles change. float_frame still answers under the global style; a styled float's edge is one cell for every style but none, as docs/plugins.md says.
