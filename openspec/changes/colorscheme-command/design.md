# Design

## Context

The palette reaches the terminal through one object: `EditorAssembly#initialize` resolves `Themes.find(options.theme, options.background)` once and hands the theme to `ScreenPresenter`, which keeps only the `SgrTable` built from it at the terminal's depth and whether it paints the background. Frames carry group ids, not colors, so nothing else holds a color. `Options` already stores, checks (`Options#problem`), and resets (`Options.shipped`) `theme` and `background`; `SetCommandHandler` only refused them through `PENDING`.

## Decisions

- The options are the one source: `:colorscheme` and `:set` change `options.theme` and `options.background` only, and `EditorAssembly#render` asks the presenter to use the palette the options name (`ScreenPresenter#use_theme(name, background)`) before presenting. The presenter compares the two strings with the ones its table was built for; on a difference it resolves the theme, builds the table again at its kept depth, and drops its last frame, so the frame is drawn in full: the screen cleared in the new Normal and every cell written in its group's new sequence. A use case never reaches an adapter, and a frame with the palette unchanged costs two string comparisons and no allocation. Alternative rejected: a port the handler calls to repaint, which would add a port for what the render already sees.
- `ColorschemeCommandHandler` (`colo[rscheme]`) is a new ex handler registered after `:set`, its row after the `:set` rows of `docs/compatibility.md`. Its argument is stripped; empty shows `options.theme`; a name `Themes.known?` accepts is stored; another is `E185: Cannot find color scheme 'name'`, as Neovim words it.
- `theme` and `background` (`bg`) join `SetCommandHandler::NAMES` in alphabetical order, so the word path handles `=`, `?`, the bare name, `&`, and E474 through `Options#problem`, and the listings show them; `PENDING` goes.
- `CompleteCommandLine` completes an argument after `colorscheme` from `Themes::NAMES` in their order, beside its path completion after the file commands, labelled by the name.

## Risks and trade-offs

- `:set all` gains two lines and the bare `:set` shows a changed theme; the snapshot and the line count of `test/editor_set_options.rb` move with it.
- A bang on `:colorscheme` is ignored rather than refused with `E477`; recorded in the compatibility Differences.
