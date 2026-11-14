feat(floats): keep a float margin, center the palette, and expose the frame

## Summary

Every editor-anchored float now keeps a one-cell margin from the screen edges, the buffer tabs, and the status bar, the palette is centered at show and again on every resize under any border style, notification titles are centered like float titles, and plugins can read the float frame, so the finder's boxes share an edge under every border. Floats touched the screen edges and bars, the palette sat one column off center without a border and never followed a resize, the finder's boxes stood two columns apart under winborder none, and a plugin's float offset was never range-checked before placement.

---

## Changes

- Change float placement to cut and move each editor-anchored box inside a one-cell margin, so it never covers the first or last column, the buffer tabs row, or the status bar row while the screen holds the box and its margin, with cursor-anchored floats following their anchor as before
- Change the widest float text to the screen less its margin and its frame, dropping the border argument every caller passed as true, so the palette, the documentation, signature, and definition floats, and the key hints never lay out a row the placement cuts
- Add a centered flag on the float window that computes the column from the box width at every arrange, and use it for the palette instead of its fixed column
- Change notification titles to be drawn centered between the corners with a blank on each side, in the severity's group, as float titles are
- Add the float_frame plugin request answering the edge, padding, and margin cells and the box width, plugin API 2.6, and size the finder's boxes from it
- Change open_float and move_float to refuse a row or column offset outside -10000 to 10000 before it reaches placement
- Fix the key hints opening an empty box when the screen leaves no text column inside the margin and frame
- Remove the shadowing of the edge reader in float placement and rewrite the frame presenter's comment and map bullet to describe the floats, their padding, border, and titles
- Add tests for the margin, centering on resize under both borders, centered notice titles, the float frame request, offset refusals, the finder edges without a border, and a narrow key hints screen, with their snapshots
- Document the margin, the centered palette, the float frame request, and API 2.6 in the README, docs/plugins.md, docs/architecture.md, and the code map, and sync the floating-windows, plugin-windows, file-finder, and messages specs from the archived change

---

## Testing

- Run the security review of the committed diff, pass with no blocking finding: 0 High, 0 Medium, and one Low at confidence 4 on the offset check at the integer minimum, recorded in the backlog
- Run the checker's stages docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, metrics, tools-test, and gates at the reviewed commit, all pass
- Run the quality review, pass on the second round after the key hints guard fix, its advisories recorded in the backlog
- Run the benchmark comparison against the recorded figures of main, pass with no regression
- Run make spec-validate after the archive, 51 of 51 pass
- Run make gates and make docs-lint on the packaged branch, all pass

---

## Notes

The plugin API rises to 2.6, a minor bump: float_frame is a new host request and FloatOptions keeps its members, so centering stays a core placement flag that plugins cannot request yet. Notifications keep their top-right placement and cursor-anchored floats such as the completion popup and hover keep following their anchor cell to the edge. The offset check's use of abs and the other review advisories are left for a follow-up in the backlog.
