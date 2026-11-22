# Proposal

## Why

`docs/design.md` section 5 decides that a selected list row is the sapphire `▎`, the SELECTION fill, and a bold label, with no `>`; section 7 lists the finder's `> ` as one of the four selection marks still shipped. Today the finder's lists mark the highlighted row with a leading `> ` in plain `NormalFloat` text, and never call `style_float`, so the row has no fill and no weight. The change is the first Sprint 29 feature item, `finder-rows`, the user's order of 2026-11-21 (design R7: lists after the elements seen on every keystroke); it is outside the numbered roadmap of `docs/architecture.md` section 12, a look item of the design.

## What Changes

- The finder's pickers (files, grep, buffers, recent) mark the highlighted row with `▎ ` instead of `> `, the other rows keeping two spaces, and style the list float after every refill with `style_float`: the highlighted row selected (the SELECTION fill of `PmenuSel`), its `▎` in the new `PmenuMarkSel` group (sapphire on SELECTION, bold) and its label in the new `PmenuLabelSel` group (the float's text on SELECTION, bold); at 16 colors both are reverse and bold, as the selected row's fill is reverse there.
- Add the UI groups `PmenuMarkSel` and `PmenuLabelSel` before `StatusLineDim`, which stays the last UI group, moving it and the syntax, file-icon, and markup ids up by two, in every palette, the bar in a new `MARK` color role (the palette's blue, a lighter blue in `dark_plus`, whose blue reads 2.9:1 on its selection) held to 3:1 as a decoration; a float span may carry them and `syntax_group` resolves them, a tokenizer's token in either still dropped. Plugin API 2.15.
- Under `NO_COLOR` a float still draws its spans in `PmenuMarkSel` and `PmenuLabelSel`, as it draws the selected row's fill; every other span (`PmenuSel`, `PmenuMatch`, a token group) stays unpainted, as today, so the palette and the command-line menu do not change.
- The grep preview's matched line takes the list's mark, so it starts with `▎ ` instead of `> `.
- Remove the finder's row from the Known drift table of `docs/design.md` section 7.

Out of scope: the matched letters in sapphire and the folder dim of design section 8's Finder note; the query row inside the float and the single frame joined by `┬ ┴`; the other three selection marks (the palette band and the tab fill, owned by `one-accent`, and the explorer's `›`, owned by `explorer-rows`); a fill or color on the grep preview's matched line, recorded in the findings file.

The backlog advisory named in the brief, "finder FRAME literal ignores winborder (carat/plugins/finder/plugin.rb:32)", no longer holds at 90b013a: the plugin has no `FRAME` constant, and `refresh` sizes its boxes from `host.float_frame(true)` (plugin.rb:426), which answers under the current border style.

Assumptions: the `▎` stays under `option.icons ascii` and `NO_COLOR`, as the acceptance asks, since the finder's rows are not drawn from the icon set; the mark keeps two cells (`▎` and a space) so the rows' text stays where it was; the label span starts after the mark's space; the empty list (`No match`, the grep hint) is not styled; `PmenuMarkSel` and `PmenuLabelSel` are UI groups, so the editor's own menus keep `PmenuSel` and no other surface changes.

## Capabilities

### New Capabilities

### Modified Capabilities
- `file-finder`: the highlighted row's mark, fill, and weight in every picker and in the grep preview.
- `plugin-host`: the float span groups (`PmenuMarkSel`, `PmenuLabelSel`), the spans drawn under `NO_COLOR`, and API 2.15.
- `color-themes`: the two groups in every palette.

## Impact

- Code: `carat/plugins/finder/plugin.rb`, `carat/domain/highlight.rb`, `carat/domain/themes.rb`, `carat/adapters/float_painter.rb`, `carat/adapters/line_painter.rb`, `carat/adapters/frame_presenter.rb` (the plain flag), `carat/use_cases/plugins/ui_requests.rb` (a comment), `carat/plugin_api.rb`.
- Tests: `test/editor_finder.rb`, `test/editor_finder_grep.rb`, `test/editor_finder_grep_preview.rb`, `test/editor_floats.rb`, `test/domain_theme.rb`, `test/use_cases_plugins.rb`, `test/domain_plugin_manifest.rb`, `test/use_cases_plugin_syntax.rb`, and their snapshots, with `test/use_cases_toggle_reading.rb`'s snapshot (a markup id moved by two).
- Docs: `docs/design.md` (the drift row removed), `docs/plugins.md` (2.15, `style_float`, `syntax_group`), `docs/compatibility.md` (the UI group count, the finder rows), `docs/architecture.md` (the `Highlight` count), `docs/codebase-map.md` (the plugin API version, `Highlight`).
- README.md: the finder sentence names the highlighted row's mark.
