# Design

## Context

The icon set is the `icons` member of `Domain::Options`, set from `option.icons` and validated against `Icons::SETS`; its default lives in three places: `config/default.caratrc` (and the generated `carat/domain/default_config.rb`, written by `make gen-config`), the `Options` constructor, and the `else` branch of `Icons.table`, which serves any set name outside the table. The painters read `state.options.icons` per frame: the float borders and the winbar's separator already switch to ASCII under `ascii` (`FramePresenter#call`), but the window separators are the constants `SEPARATOR` and `ROW_SEPARATOR` and the progress bar (`StatusBar#paint_bar`) switches only on `@plain`, set from `NO_COLOR`.

## Goals / Non-Goals

**Goals:**

- One default, `unicode`, in every place a default is read.
- `ascii` reaches every glyph the frame presenter and the status bar draw themselves.

**Non-Goals:**

- Changing the unicode table, which already meets the one-cell rule, or the nerd table.
- Following `NO_COLOR` in the separators.

## Decisions

- The default changes in the configuration, the `Options` constructor, and the `Icons.table` fallback together, so a fresh `Options`, the shipped configuration, and an unknown set name all read `unicode`. Alternative: change only the configuration line; rejected because a state built without the configuration (the tests' doubles, a plugin's fake host) would keep showing Nerd Font glyphs.
- The window separators take their glyph from the frame's options: `paint_window` already receives `options` and picks `ASCII_ROW_SEPARATOR` (`-`) or `ROW_SEPARATOR`; `paint_separators` takes the vertical glyph as an argument, chosen once in `call` as `ASCII_SEPARATOR` (`|`) or `SEPARATOR`. Both are frozen constants, so no string is built per frame. Alternative: an instance variable set in `call`; rejected as one more piece of state for a value one call computes.
- `StatusBar#paint_bar` takes an `ascii` flag, `set == "ascii"` from `paint_entry`, which already reads the set; the glyphs are ASCII when `@plain || ascii`, the done cells' group stays chosen by `@plain` alone. Alternative: route `ascii` through `plain=`; rejected because `plain` also drops the color, which `ascii` does not ask for.
- The one-cell rule is a table-driven test over `Icons::NAMES` in the default set (`Options.new.icons`, so the test follows the default), checking the glyph's length, `DisplayWidth.of`, and `DisplayWidth.private_use?`.
- The ASCII frame rule is a test in `test/adapters_frame_presenter.rb` that draws a frame with tabs, both splits, a modified buffer, and a progress report under `ascii` and scans every cell's code.

## Risks / Trade-offs

- [Tests that pinned a nerd glyph under the default configuration break] → each is updated to the unicode glyph, or to an explicit `nerd` set where the row tests nerd itself; the snapshots are rewritten with `make snapshots` and their diff read.
- [A user who relied on the default `nerd` sees the unicode set after the update] → `option.icons nerd` in their configuration selects it again; the README says so.
