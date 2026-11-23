feat(finder): show the palette and finder query inside their float

## Summary

Moves the typed query of the command palette and of every finder picker onto the first row of their modal float, with the cursor in that row and the command-line row left blank. The decided design types the query inside the float, but the finder's prompt sat on the command line with a counted title and the palette's with a bare title, so the two framed their prompt and title differently. A plugin attaches its open prompt to one of its floats through a new host request, so the host places the cursor and the plugin writes the row.

---

## Changes

- Draw the prompt row, the prompt mark then the typed text, as the first row of the palette's float and of the files, grep, buffers, and recent pickers, with the cursor bar in it and the command-line row blank while the float is shown.
- Add the plugin API request `float_prompt` (API 2.16, `PluginUi#prompt_float`, `Host#float_prompt`, `PluginLink`, `UiRequests`, `WindowRequests#holds_float?`), refused for a float the plugin does not hold and ended with the prompt.
- Title the palette's float `Commands N/M`, and have the palette and the frame presenter share one prompt constant, `Domain::Palette::PROMPT`, with the finder's own `PROMPT` holding the same text since a plugin may not name a domain constant.
- Keep the prompt on the command-line row when the screen has no room for a query row and a list row, and attach the finder's prompt to its float once for each float, not at every refill, to hold the grep allocation figure.
- Update the snapshots and version lines of the plugin host, floats, palette, finder, and command-line tests, and add tests for a wide character before the cursor and a query wider than its float.
- Update the command-palette, file-finder, and plugin-host specs, docs/plugins.md, docs/codebase-map.md, docs/compatibility.md, docs/actions.md, docs/design.md, and README.md.
- Archive the change, take it off the feature queue, and record two findings in docs/findings/prompt-in-float.md.

---

## Testing

- Security review of the committed diff, pass with no High, Medium, or Low findings
- Run the staged checks of make check at the last code commit: docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, tools-test, gates, and metrics, all pass
- Benchmark review of the allocation figures against main, pass after the finder fix, with the grep scenario back at main's count
- Run make spec-validate after the archive, 56 specs pass
- Rebuild the test runner and run make gates and make docs-lint on the packaged branch, all pass

---

## Notes

The query is cut at the float's width, not scrolled, and the grep picker keeps its two-count title; both are recorded in docs/findings/prompt-in-float.md. The left-aligned title and dim count belong to the later float-polish change. docs/architecture.md is unchanged since it is at its size budget and its request list names families that did not change.
