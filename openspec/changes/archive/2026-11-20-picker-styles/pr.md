feat(plugins): refill a plugin float in place

## Summary

Adds the plugin host request set_float_lines at plugin API 2.11, which replaces the lines and the title of one of a plugin's floats in place, and the finder now uses it to keep one list float and one preview float across keys. Before this a plugin could not change what its float showed, so the finder closed and reopened both floats on every key, building new windows and buffers and changing the window ids it held.

---

## Changes

- Add set_float_lines(window, lines, title) as a PluginApi::Host method, a PluginLink override, and a WindowRequests method: it refills the plugin's float and its title while the window id, box, z order, and focus stay, resets the float's cursor, selection anchor, and scroll to the start, and fails with "No float N" for another plugin's float, an unknown id, or a float switched to a listed buffer.
- Bump PluginApi to 2.11; a manifest written against 2.0 to 2.10 still loads.
- Change the finder to refill its list and preview floats in place while their box is unchanged, closing and reopening a float only when its box changes or the refill fails, and closing the preview when none is shown.
- Add FloatSpec#titled, the same spec with another title.
- Add tests for the refill in place, the refused refills, the 2.10 manifest still loading, and the finder keeping one float across typing and highlight moves.
- Document the request, the version history, and the finder's kept floats in docs/plugins.md and the code map, and add the plugin-host and file-finder requirements to the specs.
- Record the plan's sprint queue and the plan's entries in this change's findings file.

---

## Testing

- Run the security review of the committed diff, pass with no high, medium, or low findings
- Run the quality review, pass with no blocking findings
- Run the benchmark review, pass with no blocking findings
- Run the checker's stages (docs-lint, dev-build, test-build, diagnose, bench-budget, test-run, gates, tools-test, metrics), all pass
- Run make spec-validate after the archive, 54 passed and 0 failed

---

## Notes

The plan split the queue item: style_float(window, selected, spans) and admitting PmenuSel and PmenuMatch while other highlight ids under 65 stay refused are left to the follow-up change picker-styles-b, at the API minor after this one, so this change touches neither carat/domain/highlight.rb nor the palette's style path. Resizing a float in place is also out of scope: a box change still closes and reopens the float.
