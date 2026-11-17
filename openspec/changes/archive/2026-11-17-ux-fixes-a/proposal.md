# Proposal

## Why

The ux-pass review kept three findings the user asked to fix now (Sprint 11, item 1 of `docs/queue-feature.md`). Finding 3: the language server's status segment is drawn on the terminal's default background, a hole in the one-colored status bar, because the three `StatusLineLsp*` groups have no background of their own (`carat/domain/themes.rb:129` to `:131`), and the progress bar's done cells reuse `StatusLineLspReady` (`carat/adapters/status_bar.rb:316`). Finding 5: Enter on a finder that shows `No match` closes it and drops the typed query, because `on_input` closes before it looks for a path (`carat/plugins/finder/plugin.rb:140`), so a typo costs the whole query. Finding 10: each palette row starts with a 30-cell internal action name and cuts the readable description mid-word with no mark (`carat/use_cases/discovery/follow_palette.rb:34`, `:163`).

## What Changes

- The three `lsp` groups are drawn on the status bar's background in every shipped palette, each in a state accent picked per palette to read at 4.5:1 on that bar at 24-bit and 256 colors: three new palette roles, `PANEL_YELLOW`, `PANEL_GREEN`, and `PANEL_RED`, the accents on the bar. The progress bar's done cells follow, since they use the ready group.
- `<CR>` on a finder with no match keeps the finder open on the typed text: the prompt opens again with the text, the float still reading `No match`, and nothing is opened.
- A palette row shows the description first, the readable label, in the leading column, then the dotted name in a 30-cell column drawn in `PmenuExtra`, then the key in the 12-cell column on the right. A text cut to its column ends in `…` (`>` under `option.icons ascii`), so a cut is marked. A palette too narrow to keep 20 cells for the description leaves the name out instead of the description.

Out of scope: the order of the unfiltered palette list (finding 10 also notes it opens on `motion.repeat_find`; the acceptance names only the row's layout); the other ux-pass findings (1, 2, 4, 6 to 9, 11); a message on Enter with no match.

Roadmap: outside the roadmap of `docs/architecture.md` section 12: fixes of findings of the delivered `ux-pass` review, asked for by the user for Sprint 11.

Assumptions: the readable label is the entry's description, the only human text an entry has; an entry with an empty description shows an empty label column, as its description column is today; the threshold of 20 description cells keeps a readable label at the common widths (80 columns give 36) while the name drops first on a narrow screen; `…` is one cell wide, so the columns keep their cells, and `>` is Neovim's own truncation mark for the ascii set; the 16-color accents on the bar are the basic dark yellow, green, and red over a light gray bar and the bright ones over a blue bar; the recorded allocation figures are held since only the palette's own rows, drawn while it is open, change.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `color-themes`: the `lsp` groups read on the status bar's background instead of the editor's.
- `file-finder`: Enter with no match keeps the finder open on the typed text.
- `command-palette`: a row leads with the description, the name second in `PmenuExtra`, cuts marked; a narrow palette leaves the name out.

## Impact

`carat/domain/themes.rb` (the roles, the groups, the six palettes), `carat/plugins/finder/plugin.rb` (`on_input`), `carat/use_cases/discovery/follow_palette.rb` (rows, styles); tests in `test/domain_theme.rb`, `test/editor_finder.rb`, `test/editor_palette.rb`. No dependency, no API change, no new file.

- README.md: changed, the finder's Enter, the palette row, and the status bar's colors.
- docs/architecture.md: unchanged, it names `Themes` and `FollowPalette` without their colors or row layout, which the specs hold.
