# Proposal

## Why

The tab row shows only from two tab pages or two files, while `docs/design.md` says the open file always has a tab and `showtabline` decides whether the row shows. `docs/compatibility.md` lists `showtabline` as missing, so a user cannot ask for the row on one file or turn it off.

## What Changes

- `option.showtabline` takes 0 (the row never shows), 1 (it shows only with two or more tab pages or files, the rule until now), or 2 (it always shows); the shipped default is 2. Another value is reported as `file:line: option.showtabline takes a number from 0 to 2` and keeps the value before it.
- `BufferList#tab_row?` takes the option's value beside the tab count; `ArrangeView` and `FramePresenter` pass `options.showtabline`, so the rows reserved and the row painted agree.
- `:set showtabline=N` and `:set stal=N` join the `:set` words answered `Not implemented: :set WORD`: `:set` handles no numeric option yet, so the option is read from configuration lines only, and the compatibility row says `:set` comes with set-options.
- An `Options` built in code keeps 1 and the test configuration (`FixedConfig.defaults`) appends `option.showtabline 1`, so every existing frame without a second file keeps no tab row and no snapshot moves; `FixedConfig.shipped` is the defaults alone, which the new default row of `test/domain_options_config.rb` reads.
- Docs: the buffer-tabs and config-files specs, `docs/compatibility.md`, the README option list, `docs/architecture.md`, the code map, and `config/default.caratrc` with its generated mirror.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `buffer-tabs`: MODIFIED requirement "Buffer tabs take the top row from two buffers or two tab pages".
- `config-files`: ADDED requirement "showtabline is 0, 1, or 2".

## Out of scope

- The tab row's look: the active tab on the editor background and the modified `●` after the name are already drawn; the accent fill of the active tab and the 16-color TabLine contrast are `one-accent`'s (`docs/design.md`, Known drift).
- `:set` of any numeric option: it comes with set-options.
- No `tools/rules.sh` edit; no file of the backlog lane.
- Assumption: with showtabline 2 and no file listed (an empty buffer) the row shows, blank but for the tab-page numbers, as Neovim's always-on tabline does.
- Assumption: the option is an integer read through `bounded`, like `tabstop`, rather than an enum of words, since Neovim spells it 0, 1, 2.

## Impact

- README.md: the option list names `showtabline` and says the tab row shows from two files only under 1.
- docs/architecture.md: the `Options` and `option.<name>` lists name `showtabline`.
- docs/codebase-map.md: the `options.rb`, `buffer_list.rb`, and `fixed_config.rb` lines.
- Performance: one integer comparison per frame and per arrange; `lh` runs with the shipped default and paints a tab row on its one file, which the benchmark step compares against the recorded figures.
