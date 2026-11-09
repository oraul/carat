# Proposal

## Why

With two or more file windows on screen only the current window's file shows, in the one status bar, so the other windows say nothing about what they show, and nothing anywhere says where in the file the cursor is. The approved UI plan ends with breadcrumbs: a winbar on each file window naming its file and, when the language server knows the document's symbols, the class and method the cursor is in. The user put the remaining UI first; this is its last item, split from `layout-slots`. That change also left a gap: `<C-w>h`, `j`, `k`, and `l` pick the neighbour by layout rectangles, which no spec scenario, `docs/compatibility.md` row, or test name records.

## What Changes

- Each file window gets a winbar on its first row when the tab page shows two or more file windows: one space, the file's path (the scratch title or `[No Name]` otherwise), then, when the language server's symbols for that buffer are held, ` > ` and each symbol whose range holds the window's cursor row, outermost first. The current window's winbar is in `TabLineSel`, the others' in `TabLine`, the rest of the row `TabLineFill`. Slot and plugin windows (scratch buffers) get none and are not counted; a window of one text row keeps its row.
- A new option `option.breadcrumbs` takes `auto` (the default: the winbar shows with two or more file windows), `always`, or `never`; another word is reported as `file:line: unknown breadcrumbs mode WORD`.
- The language-server client advertises `textDocument.documentSymbol` (hierarchical), records which servers offer `documentSymbolProvider`, and, at an idle tick and only while a winbar shows, asks the current window's buffer's symbols once per text: one request in flight, sent again after its answer when the text changed, cancelled when unanswered after two seconds. Answers are read only for the request in flight, at most 500 symbols, 8 levels deep, names stripped of control characters and cut to 40 characters.
- `<C-w>h`, `j`, `k`, and `l` gain a spec scenario, a `docs/compatibility.md` row text, and test names that record the layout-rectangle rule, with an editor test on a nested split.
- Plan bookkeeping in `docs/backlog.md`: the fixed and the corrected entries the planner named, and the mouse moved out of the queue (recorded by the package step from the planner's backlog).

Out of scope: picking a symbol from the winbar or a symbol list (`:Navbar`-style navigation); `:set breadcrumbs` (the option is read from configuration lines, as `option.layout.*` are); symbol kinds and icons in the winbar; symbols of a buffer other than the current window's; a winbar on slot or plugin windows; the mouse (moved to `docs/backlog.md` by the user's decision).

This change is not a numbered item of `docs/architecture.md` section 12: it is a UI item of the T5 roadmap track in `docs/goals.md`, ordered by the user.

Assumptions: "file window" is a window of the layout showing a buffer that is not a scratch buffer, so two windows on one file count as two, as Neovim's `winbar` shows per window. The winbar reuses the header groups (`TabLine`, `TabLineSel`, `TabLineFill`) rather than adding `WinBar` and `WinBarNC`, which would need a contrast entry per palette and depth; each palette's tab-line contrast is already checked. Only the current window's buffer is asked for symbols; another window on the same buffer shows the same path, and a window on another buffer shows its file only until it becomes current. An answer arriving after the text changed is kept until the next answer replaces it, at most one idle tick (0.25 s) later, rather than cancelling on every key, which would send a request per typed key.

## Capabilities

### New Capabilities

- `breadcrumbs`: the winbar of file windows, its option, the symbol path, and the symbol requests that never delay a key.

### Modified Capabilities

- `windows`: moving to the neighbour window records the layout-rectangle rule with a nested-split scenario.

## Impact

- Domain: new `SymbolRequest`; `TabPage` gains `file_window_count` and `winbar?`; `Options` gains `breadcrumbs`.
- Use cases: `ArrangeView` reserves the winbar rows.
- Adapters: new `Winbar` painter and `SymbolOutline` reader; `FramePresenter` paints the winbars; `JsonRpcLanguageGateway` asks and reads document symbols; `EditorAssembly` wires the shared `SymbolRequest`.
- Configuration: `config/default.caratrc` (`option.breadcrumbs auto`) and its generated mirror.
- Tests: two file windows now show winbars, so window rectangles and frames of existing split tests move down one row.
- Docs: `docs/compatibility.md`, `docs/architecture.md`, `docs/codebase-map.md`, `README.md`, `docs/backlog.md`.
