fix(themes): give the cursor line the palette's text color

## Summary

Gives every cell on the cursor line two colors the palette chose, so with `cursorline` on and `option.background terminal` the text stays readable at 24 bits and 256 colors, where a cell with no foreground of its own used to keep the terminal's foreground over the palette's CursorLine stripe, dark text on a dark stripe on a light terminal. It also makes one palette table drive the theme lookup and the theme tests, so a palette missing from the lookup fails instead of silently drawing carat-dark.

---

## Changes

- Change `Themes.from_palette` so a cursor-line cell whose foreground would be the terminal's while its background is a palette color takes the palette's text color at 24 bits and 256 colors; at 16 colors the line keeps the underline as before.
- Change `from_palette` to clear the 256-color indexes of the BG and FG roles when the terminal paints them, as it already cleared their 24-bit and 16-color ones.
- Add `Themes::PALETTES` in the order of `NAMES` and look names up in it from `find`, removing the if chain, `palette`, `canonical`, and the unreachable `line_bg16`; an unknown name still gives carat-dark.
- Change `test/domain_theme.rb` to iterate `Themes::NAMES` in every palette loop and contrast table, check cursor-line contrast on both backgrounds at both depths, and fail when `NAMES` and `PALETTES` differ in length or two names share a palette.
- Change two screen presenter rows so Normal and a selection on the cursor line expect the palette's text color.
- Change the color-themes spec so the cursor-line contrast requirement covers both backgrounds and the Alias scenario says carat-light is no alias.
- Document `PALETTES` and the cursor-line rule in the codebase map, and wrap the themes comments within the comment width.
- Change the queue to the planner's sprint 7 and 8 order with the user's four decisions, record the merged runs' metrics row, and append three review advisories to the backlog.

---

## Testing

- Run the security review of the committed diff, pass with no High, Medium, or Low finding.
- Run the checker's stages (docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, metrics, tools-test, gates), all pass.
- Run the quality review, pass with no blocking finding and three advisories recorded in the backlog.
- Run the benchmark review against main's recorded figures, pass.
- Run make spec-validate after the archive, 51 items pass.
- Run make gates and make docs-lint on the packaged branch, all pass.

---

## Notes

Visual, ColorColumn, and other groups with a background but no foreground keep the terminal's foreground off the cursor line under `option.background terminal`; only the cursor line changes here. The Alias scenario keeps its name because the archive refuses a modified requirement that drops a scenario by name. The planner notes that pool item `merged-name-guard` now repeats `merge-gate-integrity`'s merged-commit check and is kept in place until the user decides.
