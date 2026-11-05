# Design

## Context

`Highlight` numbers thirteen editor groups, then thirty syntax groups; `Theme` is a `Data` value of five integer arrays by group id (24-bit foreground and background, 16-color foreground and background, attributes), built by `Themes.dark` and `Themes.light` from hand-written rows; `SgrTable.from_theme(theme, colors)` turns it into one SGR string per id once, at assembly, and `ScreenPresenter#write_run` looks the string up only when a cell's group changes. `Normal` is the bare reset, so the terminal paints the background. A plugin's tokens are filtered by `Highlight.syntax?` and its group names resolved by `Highlight.syntax_id`. The explorer draws its tree as plain scratch lines.

## Goals / Non-Goals

**Goals:**

- Palettes that a user of Neovim or VS Code recognizes, small enough to read and to check: each a list of named colors, with one table saying which color every group takes.
- No cost per key: the SGR table stays the one structure the presenter reads, built once.
- A contrast rule enforced by a test, not by review.

**Non-Goals:**

- Drawing the new UI groups the editor has no part for yet, switching the theme at run time, user themes.

## Decisions

### 1. Groups: UI tokens, then syntax, then file icons

The ids are renumbered: 41 UI groups from 0 (the thirteen of today keep their order and constants), the thirty syntax groups from `SYNTAX_FIRST` 41, and thirteen file-icon groups from `ICON_FIRST` 71 to `COUNT` 84. `Highlight.token?(id)` is true for syntax and icon ids, the groups a plugin token may carry, and `Highlight.token_id(name)` resolves both; `syntax?` keeps its meaning. Ids are resolved by name at activation, so no plugin depends on the numbers. Alternative: append the new UI groups after the syntax groups to keep the old numbers; rejected because the ranges would interleave and every range test would need two comparisons.

### 2. A palette is roles; one table maps groups to roles

`Themes` names 37 color roles (`BG`, `FG`, `DIM`, `FAINT`, `PANEL`, `FLOAT`, `SELECTION`, `SEARCH`, the seven accents, the four diff backgrounds, and thirteen syntax roles such as `COMMENT`, `KEYWORD`, `CONTROL`, `FUNCTION`, `TYPE`, `STRING`). A palette is rows of four integers per role: the 24-bit color, its 256-color index or -1 to take the nearest, and its 16-color index or -1 for none. One shared table gives each group a foreground role, a background role (-1 for none), its attributes, and its attributes at 16 colors. Per-palette syntax colors come from the roles: `one_dark`'s `KEYWORD` and `CONTROL` are both purple, `dark_plus`'s are blue and pink. Alternative: rows per group per palette as today (four tables of 84 rows); rejected as four times the data with nothing to keep the palettes consistent.

The 16-color indices are given by hand per role and palette, as Vim themes give `ctermfg`, since the nearest basic color to a pastel is white. The 256-color index is given only where the nearest one fails the contrast test (seven roles in three palettes).

### 3. Theme gets 256-color and 16-color-attribute arrays

`Theme` becomes `Data.define(:name, :fgs, :bgs, :fgs256, :bgs256, :fgs16, :bgs16, :attrs, :attrs16)`; `SgrTable.sequence` takes `fg256` when it is not negative and the nearest index otherwise, and at 16 colors writes `attrs16` instead of `attrs`. `Theme.from_rows` goes away with its only caller.

### 4. The background is resolved when the theme is built

`Themes.find(name, background)` builds the theme for one background. With `terminal`, the roles `BG` and `FG` resolve to -1 at every depth, so `Normal` is the bare reset and every group whose role is the palette's text color keeps the terminal's, as today. With `theme`, a group's missing foreground or background takes `FG` or `BG`. The presenter learns only `Theme#paints_background?` (Normal has a background): when true, `full` writes the Normal sequence before `\e[2J` and the scroll code writes it instead of `\e[0m` before a scroll region, so the terminal's background color erase fills cleared and scrolled-in cells with the palette's background; blank cells are skipped as before. In the terminal background the bytes written are unchanged. Alternative: write every blank cell; rejected because it multiplies the bytes of a full frame.

### 5. The contrast test

`test/domain_theme.rb` builds each palette with the theme's background and measures every group's foreground against its background with the WCAG 2 relative luminance, 4.5:1 for text groups and 3:1 for decorations, at 24 bits and at the 256 colors `SgrTable` writes (the cube and gray ramp converted back to 24 bits). The palettes were tuned until it passed: One Dark's comment gray, red, and line numbers are a step lighter than Atom's, and One Light's yellow, green, cyan, and blue a step darker. A table row per palette names the groups that fail, so a failure says which.

### 6. Icon colors through the tokenizer path

The explorer declares the filetype `explorer`; `WindowRequests#open_scratch` gives a new scratch buffer the syntax named after its plugin when the plugin declares that filetype, so `HighlightView` asks the explorer to tokenize its tree like any buffer, with `:syntax off` and the guard applying as they do. The explorer resolves the icon groups in `activate`, records each tree line's group when it renders the lines, and `tokenize` answers one token, the icon's column (one code point for the marker plus the indentation spaces) with length one. Equal line text always has the same icon, since the icon follows the name and the kind of entry shown in the text. Alternative: a host request returning an icon's group with the glyph; rejected because a scratch line has no per-cell style but the tokens. API 2.1, a minor bump: requests widen, nothing is removed.

## Risks / Trade-offs

- [The alias `carat-dark` changes its colors] → it is an alias by request; the README and `docs/compatibility.md` say so.
- [A terminal without background color erase leaves cleared cells unpainted with `background theme`] → the default is `terminal`; the README names the requirement.
- [The renumbered ids change the snapshots that print ids] → the tests name constants, not numbers.
