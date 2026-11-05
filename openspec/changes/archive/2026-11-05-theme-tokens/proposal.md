# Proposal

## Why

Carat ships two hand-tuned themes that leave the screen to the terminal and name only the thirteen groups the editor draws today, so the UI track (bars, floating windows, the finder, the start screen) has no colors to draw with and no palette a user of Neovim or VS Code would recognize; nothing checks that text is readable, which goal 9 asks for. This change is outside the numbered roadmap of `docs/architecture.md` section 12: it is the first change of the UI track the user approved (queue item 12), extending the themes of item 8, taken now under the every-three rule.

## What Changes

- The highlight groups grow to 41 UI tokens with Neovim's names: the thirteen of today plus `CurSearch`, `CursorLine`, `CursorLineNr`, `ColorColumn`, `EndOfBuffer`, `WinSeparator`, `Directory`, `Title`, `WarningMsg`, `ModeMsg`, `MoreMsg`, `Question`, `MatchParen`, `Pmenu`, `PmenuSel`, `PmenuSbar`, `PmenuThumb`, `NormalFloat`, `FloatBorder`, `DiffAdd`, `DiffChange`, `DiffDelete`, `DiffText`, `Whitespace`, and the four `Diagnostic` groups; the thirty syntax groups follow, then thirteen file-icon groups (`DevIconDefault`, `DevIconFolder`, `DevIconSymlink`, `DevIconRb`, `DevIconJson`, `DevIconMd`, `DevIconToml`, `DevIconMakefile`, `DevIconSh`, `DevIconC`, `DevIconYml`, `DevIconGitIgnore`, `DevIconLock`).
- Four palettes, `one_dark` (the new default), `one_light`, `dark_plus`, and `light_plus`, each a set of named colors with its own syntax colors, `Search` and `IncSearch` included; every group takes its colors from a shared table of roles. `carat-dark` and `carat-light` stay accepted as aliases of `one_dark` and `one_light`.
- A palette color may carry its own 256-color index where the nearest one would lose contrast, and every group has 16-color attributes used when the terminal has only 16 colors (reverse for the selection, underline for the cursor line), so a group without a basic color still shows.
- A new `option.background` line: `terminal` (the default) leaves the terminal's own background and foreground for `Normal`, as today, and `theme` paints the palette's background and foreground under every cell.
- The explorer colors each entry's icon by its file type, through the file-icon groups, which a plugin may now resolve and give its tokens; a scratch buffer of a plugin that tokenizes the filetype named after the plugin is highlighted by it. Plugin API 2.1.
- A contrast test checks every palette at WCAG AA: 4.5:1 for every text group and 3:1 for decorations (tilde rows, separators, borders, whitespace, signs, icons), at 24-bit colors and at the 256 colors the terminal is sent.
- Documentation: `docs/compatibility.md` (the `background` and `theme` rows), `docs/plugins.md`, `docs/architecture.md`, the README, the code map, and `docs/backlog.md`.

Out of scope: the current-line highlight and the cursor shapes per mode (queue item `cursor-shapes`), `:colorscheme`, `:highlight`, `:set background` and `:set theme`, user theme files, and drawing the new UI tokens other than icons (each arrives with the change that draws its part).

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `color-themes`: the UI tokens, the four palettes and the aliases, the background option, 256-color values and 16-color attributes, and the contrast rule.
- `plugin-host`: `syntax_group` resolves the file-icon groups too, tokens may carry them, a plugin's scratch buffer takes the plugin's filetype, API 2.1.
- `file-explorer`: icons are drawn in their file type's color.

## Impact

- Code: `carat/domain/highlight.rb`, `theme.rb`, `themes.rb`, `options.rb`; `carat/adapters/sgr_table.rb`, `screen_presenter.rb`, `editor_assembly.rb`; `carat/use_cases/plugins/ui_requests.rb`, `plugin_syntax.rb`, `window_requests.rb`; `carat/use_cases/ex/set_command_handler.rb`; `carat/plugin_api.rb`; `carat/plugins/explorer/`; `config/default.caratrc` and its generated mirror.
- Tests: `test/domain_theme.rb` (palettes, aliases, background, the contrast table), `test/adapters_screen_presenter.rb` (sequences of the new palettes, 256 values, 16-color attributes, the painted background), `test/editor_explorer.rb` (icon colors), `test/domain_plugin_manifest.rb` (API 2.1), and the option tests.
- Allocations per key: the SGR table is still built once at startup and a cell still costs one array read, so `lh`, `j`, and `insert` keep their figures.

Assumptions recorded here:

- `background` defaults to `terminal`, which keeps today's output; the brief names both behaviors and not the default.
- Neovim's `background` option names `dark` or `light`; Carat's names who paints the background, since `theme` already picks the palette. The difference is recorded in `docs/compatibility.md`.
- Today's `carat-dark` colors are replaced: the alias draws `one_dark`, as the brief asks.
- The file-icon group names follow nvim-web-devicons (`DevIconRb`, ...), with `DevIconFolder` and `DevIconSymlink` added for the tree's own entries.
