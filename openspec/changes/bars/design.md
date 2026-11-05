# Design

## Context

`FramePresenter` paints a status line per window (`paint_status`, `paint_ruler`) and a tab line of tab pages (`paint_tabline`, `file_name`) every frame. Two of those paths allocate per frame: `segments.values.join(" ")` when a plugin has a segment, and the interpolated label plus the `byteslice` of the base name per tab page. `ArrangeView` reserves row 0 when there are two tab pages. The theme has 41 UI groups with Neovim names; plugins set segments with `set_status` into `PluginUi#segments`. The explorer plugin owns the file-icon table (`Plugins::Explorer::FileIcons`).

## Goals / Non-Goals

**Goals:** one bar and one top row painted without allocating, testable on their own against a `Frame`; the window geometry unchanged, so no layout or window command moves; the slots the language and git changes fill exist with their place, priority, and colors.

**Non-Goals:** filling the slots, configurable segment lists, clickable tabs, `laststatus` and `showtabline` options.

## Decisions

### The geometry stays; the status rows become the bar and separator rows

`Layout#arrange` keeps giving every window its text rows plus one row under them. The frame presenter paints that row as a horizontal separator (`─` in `WinSeparator`) when it is not the bar row (`rows - 2`), and paints nothing there when it is; after the windows and the vertical separators it paints the bar across the whole row. Neovim's `laststatus=3` keeps the same one-row separator, so split sizes, `<C-w>` commands, and every window test that counts rows keep their numbers. Alternative: give the bottom windows the bar row back to the layout, which would change every split's arithmetic and the `E36` rules for nothing visible.

### Two painters in the adapters layer

`Adapters::StatusBar` (`paint(frame, row, cols, state)`) and `Adapters::TabBar` (`paint(frame, state, cols)`) are plain classes built once in `EditorAssembly` and handed to `FramePresenter` as `status_bar:` and `tab_bar:`; the presenter only calls them and records their rows as chrome. Each can be tested with a bare `Frame` and a state, per segment and per width. `StatusBar` takes `plugin_ui:` and `slots:`; `TabBar` takes `buffers:`. Keeping them out of the 860-line presenter keeps each file one concern.

### Slots as one domain record

`Domain::StatusSlots` is a `Struct` with `branch`, `errors`, `warnings`, `infos`, `hints`, `lsp_name`, and `lsp_state` (`:none`, `:starting`, `:ready`, `:error`), built once in `EditorAssembly` and held by the status bar. Nothing writes it in this change; the language-services and git changes will. An empty slot is width 0 and so absent, but its index in the fixed order is kept, which is what "keeps its place" means: filling `lsp` never moves the plugin segments before it.

### Priorities without allocation

Per frame the bar fills three reusable integer arrays (kind, width, priority) with one entry per present segment, computed arithmetically: `Frame.digits` for numbers, `DisplayWidth.text_width(text, from)` (new, walking bytes as `Frame#put_within` does) for texts. While the sum exceeds the width it marks the entry of lowest priority, the later one on a tie, as dropped. Then it paints the left entries from column 0 and the right entries ending at the last column, each piece with `Frame#put_within` and `put_digits`. The arrays are cleared and refilled, which, like the presenter's `@chrome`, does not allocate once they have grown. Plugin segments are read in registration order through `PluginUi#owners`, a list kept beside the `segments` hash, and their priorities through `PluginUi#priorities`, so no `values` or `keys` array is built.

Priorities: mode 100, file 90, position 80, diagnostics 70, `lsp` 60, percent 50, branch 40, file type 30, encoding 20, plugins their own (0 to 99, `set_status` 10). The mode and file are cut at the edge rather than dropped, so the bar never goes blank.

### Buffer tabs without allocation

`TabBar` reads `BufferList#buffers`, skipping scratch buffers. A tab's name is the path from the byte after its last `/`, written with `Frame#put_from` (new: `put_within` from a byte offset) and measured with `DisplayWidth.text_width` from the same offset, so no base name string is made. The icon is `Buffer#icon`, the icon name computed with the filetype when the buffer is made or renamed, so the per-frame path does not cut extensions; its glyph is `Icons.glyph(icon, set)`, a constant, and its group is resolved once per name through `Highlight.token_id`. Overflow: with a reserve for both counts (digits of the file count plus three each), the run starts at the first tab and moves right one tab at a time until the current tab fits in it, then extends right while tabs fit. Tab-page numbers are painted first from the right end and the tabs get the columns before them.

### The row shows from two files or two tab pages

`BufferList#tab_row?(tab_count)` answers whether the top row shows; `ArrangeView` (now taking `buffers:`) and the presenter both ask it, so the layout and the paint agree. Bufferline hides a lone tab by default, and a one-file session keeping its rows keeps most tests and the start screen unchanged.

### Theme groups and a role for text on accents

Eight UI groups follow `DiagnosticHint` (ids 41 to 48), moving the syntax groups to 49 and the file-icon groups to 79; every reference is by constant or by name, so only the count test changes. The mode pills need light text on the light palettes' dark accents and dark text on the dark palettes' light accents, which no role gives, so the palettes gain `ON_STRONG` (each palette's background color, kept when the terminal paints the background). The diagnostics counts reuse the `Diagnostic*` groups and the `lsp` groups put their accent on the editor's background as those do, so they read like cut-outs of the bar: on `PANEL` One Dark's red and blue fall under 4.5:1, and on `PANEL_NC` Dark+'s red and the light palettes' green at 256 colors do.

### One file-icon table in the plugin API

The table that maps a file name to an icon name and an icon name to its group moves from `Plugins::Explorer::FileIcons` into `PluginApi::FileIcons`, the plugin API being the only file both the explorer and the core may name. The explorer's `FileIcons` keeps `name_for` (folders and links) and delegates the file case. Alternative: a second table in the domain, which the quality review would rightly call a copy.

### The API version

`set_segment(text, priority)` is a `Host` method, a `PluginLink` override, and `UiRequests#set_segment`, so `MINOR` becomes 2 and `VERSION` "2.2"; a 2.1 manifest is still accepted, `set_status` stays.

## Risks / Trade-offs

- [Non-current windows lose their own file name line] → as in Neovim with `laststatus=3`; a winbar is a later change of the UI track.
- [Eight new groups shift the syntax ids] → nothing stores ids across runs; plugins resolve groups by name.
- [Tests that open a second file see their rows move down one] → the snapshot diffs are reviewed; the behavior is the new spec.
- [Equal base names show twice] → disambiguation is out of scope and noted in `docs/compatibility.md`.
