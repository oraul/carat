# Backlog: test/domain_theme.rb

### The theme test's BG and FG 256-color row proves nothing new
- Location: test/domain_theme.rb:453
- Why: every shipped palette already gives -1 as the BG and FG 256-color index, so this row passed before the change and no test fails if the indexes256[BG]/[FG] clearing at carat/domain/themes.rb:510-511 is removed; quality advisory from carat-palette-b.
- Fix: add a row that calls D::Themes.from_palette with a small palette giving FG and BG a 256 index and asserts fg256/bg256(H::NORMAL) are -1 when not painted.
- Also: carat/domain/themes.rb
- Category: code-quality
- Added: 2026-11-15

### The theme palette lookup row misses a reordered PALETTES
- Location: test/domain_theme.rb:376
- Why: the lookup row checks only that the lengths match and no two palettes are equal, so a reordered PALETTES (ONE_DARK and ONE_LIGHT swapped, say) still passes and draws another palette for a name, which the proposal says this row prevents; quality advisory from carat-palette-b.
- Fix: assert each name's find(name, "theme").bg(H::NORMAL) against a table of each palette's BG color.
- Category: code-quality
- Added: 2026-11-15

### The panel color cases check the role the sprint did not change (sprint-18 review quality)
- Location: `test/domain_theme.rb:551`.
- Why it matters: the cases check `bg(H::STATUS)` (0x2e3346, 0xe3e6ef) while the label names the PANEL_NC and FLOAT change.
- Fix outline: drop the block or check TAB_LINE, STATUS_NC, and NORMAL_FLOAT.
- Category: code-quality
- Added: 2026-11-18
