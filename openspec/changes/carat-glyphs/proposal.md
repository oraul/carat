# Proposal

## Why

The default icon set, `nerd`, draws its 33 glyphs from Nerd Font code points in the private use areas, so a terminal with a stock font shows boxes in the status bar, the tabs, the signs, and the explorer until the user finds the `icons` option. And `option.icons ascii`, the set for terminals that can show only ASCII, still draws the window separators and the progress bar in box drawing characters. This is sprint 5's fourth item of `docs/queue.md`, a user decision; it delivers no new roadmap item of `docs/architecture.md` section 12 and refines the icons the plugin host roadmap item shipped. It closes the backlog item "Window separators and the progress bar ignore option.icons ascii".

## What Changes

- The default icon set becomes `unicode` (the existing table of triangles, bullets, and geometric shapes): `config/default.caratrc` and its generated mirror read `option.icons unicode`, a fresh `Options` holds `unicode`, and `Icons.glyph` reads an unknown set as the default set, `unicode`.
- `nerd` stays a valid value of `option.icons`, selected by a configuration line as before.
- A table-driven test checks that every glyph of the default set is one character, one cell wide by `DisplayWidth`, and outside the private use areas.
- Under `option.icons ascii` the window separators are `|` (between side-by-side windows) and `-` (the row under a stacked window), and the progress bar's done cells are `#` and the rest `-`; the done cells keep `StatusLineLspReady` unless `NO_COLOR` is set.
- A test draws a frame under `option.icons ascii` with both splits, two tabs, a modified buffer, and a progress bar, and finds no byte above 127 in it.
- The README, `config/default.caratrc`'s comments, and `docs/plugins.md` name `unicode` as the default.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `icons`: the default set is `unicode`; the default set's glyphs are one cell wide and outside the private use areas; `nerd` stays selectable.
- `screen-rendering`: the window separators under `option.icons ascii`, and an ASCII frame under that set.
- `status-bar`: the progress bar's glyphs under `option.icons ascii`.

## Impact

- Code: `carat/domain/icons.rb` (the unknown-set fallback), `carat/domain/options.rb` (the fresh default), `config/default.caratrc` and the generated `carat/domain/default_config.rb`, `carat/adapters/frame_presenter.rb` (the separators), `carat/adapters/status_bar.rb` (the progress bar).
- Tests: `test/domain_icons.rb`, `test/domain_options_config.rb`, `test/adapters_frame_presenter.rb`, `test/adapters_status_bar.rb`, and the tests whose expectations held a nerd glyph under the default configuration (`test/editor_tabs.rb`, `test/editor_windows.rb`, `test/editor_insert.rb`, `test/editor_plugins.rb`, `test/use_cases_plugins.rb`, `test/use_cases_plugin_hardening.rb`, `test/smoke_editor.rb`, as each one turns out to depend on it), with their snapshots.
- Docs: `docs/plugins.md` (the default set), `docs/codebase-map.md` (the separator and progress lines, if they name the glyphs).
- README.md: changed, the icons section names `unicode` as the default and `nerd` as the set that needs a Nerd Font, and the ASCII set's separators and progress bar.
- docs/architecture.md: unchanged, it names the three sets and the option, not which set is the default or the separator glyphs.
- Bench: the separators and the bar cells are constants chosen per frame, so no string is built and no allocation or round is added.

Assumptions:

- `Icons.glyph` with a set name outside `SETS` (reachable only by a caller passing one directly, since the option refuses it) reads the default set, now `unicode`, rather than `nerd`, so the fallback and the default agree.
- `option.icons ascii` changes the glyphs only: the progress bar's done cells keep `StatusLineLspReady` under it, as the tab bar's and status bar's icons keep their groups; `NO_COLOR` alone still drops the color.
- `NO_COLOR` without `option.icons ascii` keeps the box drawing separators, as today; only the float borders and the progress bar followed it before, and the brief asks only for `ascii`.
- The ASCII frame check covers what the editor draws itself over ASCII buffer text; buffer text outside ASCII is the user's and is drawn as it is.

Out of scope: deprecating or removing `nerd`, new glyphs of carat's own, changes to the unicode table's glyphs, the separators or the bar under `NO_COLOR` alone, and the queue's order.
