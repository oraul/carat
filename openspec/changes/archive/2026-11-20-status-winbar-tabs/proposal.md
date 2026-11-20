# Proposal

## Why

`[No Name]` is defined in three adapters (`StatusBar`, `Winbar`, `TabBar`) and again as literals in `ListBuffers` and `Messages.unsaved_buffer`, so a change of the word needs five edits. The status bar's Facet look (mode pill, panel bar) has no test that reads its frame row in each theme and in `option.icons ascii`. This is part a of a split of the queue item `status-winbar-tabs`; the winbar and the tabs' styling is `status-winbar-tabs-b`.

## What Changes

- `carat/domain/messages.rb`: `Messages::NO_NAME`, the one word for a buffer with no path or title.
- `StatusBar`, `Winbar`, and `TabBar` drop their own `NO_NAME` and read `Domain::Messages::NO_NAME`; `ListBuffers` and `Messages.unsaved_buffer` read it instead of their literal. The text shown is unchanged.
- `test/adapters_status_bar.rb`: the unnamed row is built from the constant, and the status bar's frame row is checked in carat-dark and carat-light (the pill, file, and fill groups, and that the theme's pill and bar colors differ and are readable) and under `option.icons ascii`.
- `test/adapters_tab_bar.rb`: the unnamed tab is built from the constant.
- `docs/codebase-map.md`: `Messages` lists `NO_NAME`.

## Capabilities

### New Capabilities

None: no behavior changes (`skip_specs: true`).

### Modified Capabilities

None.

## Out of scope

The winbar's and the tabs' styling and the `lh-winbar` check (`status-winbar-tabs-b`).

- README.md: unchanged, no behavior or file changes.
