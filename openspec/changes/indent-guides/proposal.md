# Proposal

## Why

Deeply nested code is hard to follow in a terminal editor without a visual cue for which lines share a block; the user asked for indent guides (`docs/queue.md` item 4, a T5 user request) to be delivered now, before the project goes on hold. This change is outside the roadmap of `docs/architecture.md` section 12, which lists no indent guides: it is the user's direct request.

## What Changes

- File windows draw a dotted vertical guide (`┊` by default) at each `shiftwidth` level inside a line's leading whitespace, `tabstop` standing in when `shiftwidth` is 0.
- A blank or whitespace-only line carries the guides of the indentation around it: the smaller of the nearest non-blank line's indent above and below.
- In the current window, the guide of the block the cursor is in is drawn in a highlight group of its own over the rows of that block.
- Two new UI groups, `IblIndent` and `IblScope` (the names of Neovim's indent-blankline plugin), colored in every shipped palette as decorations (3:1), on the cursor line too.
- `option.indentguides` (true or false; off in fresh options as Neovim draws no guides, on in the shipped configuration) and `option.indentguides.char` (one character one column wide, `┊` by default); with `option.icons ascii` a non-ASCII guide character is drawn as `|`.
- Plugin windows (the explorer, pick lists), floats, and the start screen draw no guides.
- Bench scenarios `lh-noguides`, `j-noguides`, and `insert-noguides` measure the keys with the guides off, the shipped `lh`, `j`, and `insert` with them on.

## Capabilities

### New Capabilities

- `indent-guides`: the guides drawn in file windows, carried across blank lines, the cursor's block highlighted, and their two options.

### Modified Capabilities

- `color-themes`: the UI groups gain `IblIndent` and `IblScope` (51 groups), held to the decoration contrast of 3:1.

## Out of scope

- `:set indentguides` and `:set` of the character: the guides are configuration options read at startup, as `theme` and `breadcrumbs` are; `:set` for Carat's own options stays in `docs/backlog.md`.
- Scope detection by syntax (indent-blankline's tree-sitter scope), guides in non-current windows' blocks, a per-level color cycle, and guides past the end of a line's whitespace (Neovim's `listchars` `leadmultispace`).
- The cursor-line text contrast of 3.90 to 4.43:1 that queue item `theme-tidy` records; the guides are decorations, held to 3:1.

## Impact

- `carat/adapters/indent_guides.rb` (new): measures the visible rows' indents and the cursor's block, and paints the guides.
- `carat/adapters/frame_presenter.rb`, `carat/adapters/painted_rows.rb`: the guides drawn in file windows' rows, a row's guide key an input of its repaint.
- `carat/domain/highlight.rb`, `carat/domain/themes.rb`: the two groups, the ids after them moved by two.
- `carat/domain/options.rb`, `config/default.caratrc`, `carat/domain/default_config.rb`: the two options.
- `bench/keys.rb`, `bench/run.sh`: the three scenarios with the guides off.
- Tests: `test/adapters_indent_guides.rb` (new), `test/domain_options_config.rb`, `test/domain_theme.rb`.
- `docs/compatibility.md` (an Indent guides section, the Themes count), `docs/codebase-map.md` (areas 13 and 14, the scenarios), `docs/queue.md` through the package step.
- README.md: changed, the option list names `indentguides` and `indentguides.char`.
- docs/architecture.md: changed, `Options`, the `.caratrc` option scope, and section 8.2's `FramePresenter` name the guides.

## Assumptions

- The guides are on in the shipped configuration, as `cursorline` is, since the user asked for them; fresh `Options` keep Neovim's behavior of none.
- The ASCII fallback is `|`, chosen by the existing ASCII switch, `option.icons ascii`, rather than a second switch; an ASCII guide character is kept as set.
- A blank line's carried indent is the smaller of its neighbors', so a guide never dangles into the blank line before a dedent; the search for a neighbor stops after 1000 lines, counting a farther one as no indent.
- The cursor's block is found by indentation: its guide is the deepest level below the cursor line's indent, over the contiguous rows indented past that level.
