fix(floats): fit float text beside the whole frame

## Summary

Floats now size their text to the screen less their whole frame, the padding on each side plus the border when one is drawn, so no row the palette, hover, signature, definition peek, or key hints lay out is cut at the right edge, and the finder's list and preview boxes share an edge. Each of these sized its text as the screen less the border alone while placement also kept a column of padding on each side, so every row lost two columns on narrow screens and the finder's literal sizes assumed a bordered box.

---

## Changes

- Add one frame-width rule to the float window, frame_width and text_room, which place also uses to cut a box, so the text area and the placed box agree under every option.winborder value
- Change the palette, the documentation float, the signature float, the definition peek and pick list, and the key hints to size their text by that rule, so an 80-column hover row wraps at 76 columns and shows its last word and under winborder none the two edge columns are used
- Change the finder to lay out its boxes from a named one-column margin and the documented box frame instead of literals, so with a drawn border the list and preview boxes share an edge
- Add frame tests for a shrinking palette filter at 120 by 36 and 60 by 24 under both borders, an 80-column hover row, narrow signature and definition floats, the finder box edges under both borders, the key hints width under winborder none, and the rule and place in the float layer test
- Document in the README that a float's text fits beside its padding and border, and sync the floating-windows and file-finder specs from the archived change

---

## Testing

- Run the security review of the committed diff, pass with no findings: 0 High, 0 Medium, 0 Low
- Run the checker's stages docs-lint, test-build, test-run, diagnose, metrics, and gates at the reviewed commit, all pass, with dev-build, bench-budget, and tools-test carried from the previous commit as unchanged
- Run the quality review, pass with no blocking finding, its advisories recorded in the backlog
- Run the benchmark comparison against the recorded figures of main, pass with no regression
- Run make spec-validate after the archive, 51 of 51 pass
- Run make gates and make docs-lint on the packaged branch, all pass

---

## Notes

Under winborder none the finder's boxes still stand two columns apart and the palette sits one column left of center, because a plugin cannot yet read the frame width; exposing it through the plugin API, placement at show and on resize, and notice titles are the next queue item, float-placement. The 120 by 36 palette frame already drew every right border at the box edge before this change, so the test pins it there and shows the old cut rows at 60 by 24.
