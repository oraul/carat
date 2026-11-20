# Proposal

## Why

Nothing in Carat shows where a tab, a trailing blank, or a no-break space sits: `config/default.caratrc` has no `listchars`, `option.list` is an unknown option, and a tab paints as blank cells. The user's Facet decisions (wave 2, a T2 request, `docs/queue-feature.md` Sprint 24 item 1) ask for Neovim's `list` and `listchars` with Facet's quiet marks. The change is outside the roadmap of `docs/architecture.md` section 12, which lists no whitespace marks: it is the user's request.

## What Changes

- `option.list` (true or false, off in fresh options and in the shipped configuration, as Neovim) turns the whitespace marks of file windows on.
- `option.listchars` takes Neovim's keys `tab:xy[z]`, `trail:c`, and `nbsp:c`, comma-separated; fresh options hold Neovim's default `tab:> ,trail:-,nbsp:+` and the shipped configuration Facet's `tab:→ ,trail:·,nbsp:␣`. A key left out draws no mark; another value is reported as a `file:line` problem, the value before it kept.
- With `option.icons ascii` a mark outside ASCII is drawn in Neovim's default form: `>` and a blank for a tab (`>` for its last cell), `-` for a trailing space, `+` for a no-break space.
- The marks are drawn over the text cells of file windows' rows in `Whitespace`, which takes the indent guides' color role (carat-dark #30364b, carat-light #d8dce8, basic color 8 at 16 colors); under `NO_COLOR` the mark characters still show. Plugin windows, floats, and closed fold rows draw none.
- `:set list` and `:set listchars` answer `Not implemented: :set list`, as the other options Carat reads only from configuration lines.

## Capabilities

### New Capabilities

- `whitespace-marks`: the `list` and `listchars` options and the marks they draw in file windows.

### Modified Capabilities

- `color-themes`: `Whitespace` takes the indent guides' color in every palette, so in carat-dark and carat-light it recedes with the guides instead of keeping the decorations' 3:1.

## Out of scope

- The closed fold's look (its text and fill in `Folded`, one cell of padding), the second half of the queue item, is split off and queued as feature Pool 2 `folded-row`.
- Neovim's other `listchars` keys (`space`, `lead`, `leadmultispace`, `multispace`, `eol`, `extends`, `precedes`, `conceal`), which are refused; `:set list` and `:set listchars` themselves, which arrive with the options change; window-local `list`.

## Impact

- `carat/domain/options.rb`, `config/default.caratrc`, `carat/domain/default_config.rb` (by `make gen-config`): the two options, their check, and the mark code points with the ascii form.
- `carat/adapters/whitespace_marks.rb` (new): the marks' settings stamp and their paint over a decoded line.
- `carat/adapters/frame_presenter.rb`: the marks painted in file windows' text rows, their stamp in the frame's geometry key.
- `carat/domain/themes.rb`: the `Whitespace` row takes the `GUIDE` role.
- `carat/use_cases/ex/set_command_handler.rb`: `list`, `listchars`, and `lcs` among the options `:set` does not handle yet.
- Tests: `test/adapters_whitespace_marks.rb` (new), `test/domain_options_config.rb`, `test/domain_theme.rb`, `test/editor_syntax.rb`, `test/runner/run_all.rb`.
- `docs/compatibility.md` (a Whitespace marks section, the option rows, the `:set` paragraph), `docs/codebase-map.md` (area 13: the new file and test).
- README.md: changed, the option list names `list` and `listchars`.
- docs/architecture.md: changed, `Options`, the `.caratrc` option scope, and section 8.2's `FramePresenter` name the marks.

## Assumptions

- Fresh `Options` hold Neovim's default `listchars`, and the shipped configuration Facet's Unicode marks, as the indent guides keep Neovim's behavior in fresh options and Carat's look in the shipped file; the ascii form is Neovim's default characters, chosen by the existing `option.icons ascii` switch.
- A later key of the same name in one `listchars` value wins, as in Neovim; an empty value (`""`) draws no mark.
- A no-break space is U+00A0 or U+202F, Neovim's two; a trailing space is a space after the line's last other character, so a line of spaces only is all trailing.
- The marks are painted after the syntax tokens and the indent guides and before the search matches and the selection, so a tab's mark shows over a guide in its cell, as indent-blankline draws a tab's `listchars`, and a match or selection colors the mark's cell as it colors text.
