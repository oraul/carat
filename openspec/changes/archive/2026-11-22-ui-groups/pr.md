feat(status-bar): group the bar segments with a quiet dim color

## Summary

The status bar now draws its segments in groups: the branch, file type, encoding, and a stateless language server step back in a quiet text color, while the file, position, and percent keep the bar's text, and the visual mode indicators of the message row are dim. This follows the status bar groups of the design document, so the mode pill is the one sapphire fill and the quiet details no longer compete with the file name. The quiet color is a new PANEL_DIM role with at least 4.5:1 contrast on the bar background in every palette.

---

## Changes

- Add the PANEL_DIM color role to every palette, the design's values in carat-dark and carat-light and a value of at least 4.5:1 on the bar background in the other four, with the bar's text color as its 16-color basic color.
- Add the StatusLineDim highlight group after Folded, moving the syntax, file-icon, and markup ids up by one.
- Draw the branch, file type, encoding, and a server slot without a state in StatusLineDim, leaving the file, position, percent, plugin segments, and progress label in StatusLine.
- Put one more cell before each segment that starts an independent group, so groups are three cells apart and the pill, file, position, and percent two, with no separator glyph.
- Draw the three visual mode indicators of the message row in MsgDim instead of Normal.
- Update the status-bar, color-themes, and screen-rendering specs, the compatibility segment table and group count, the codebase map, the architecture Highlight count, and the README status bar sentence.
- Update the status bar, frame presenter, and theme tests and snapshots, and the spacing expectations of two other tests, to show each group's color and spacing and the contrast at 16 colors and with NO_COLOR.

---

## Testing

- Run the security review of the committed diff at the checked head, no High, Medium, or Low findings, nothing blocking.
- Run the benchmark review at the checked head, no blocking finding.
- Run the full check at the checked head, docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, tools-test, gates, and metrics all pass.
- Run make spec-validate after the archive, 56 specs pass.
- Run make gates and make docs-lint at the packaged head, both pass.

---

## Notes

The design's folder segment and server-as-one-dot, the quiet progress bar cells and percent, and the sapphire selected tab owned by the one-accent change are out of scope and recorded in the findings file.
