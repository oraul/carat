# Proposal

## Why

After `:LspRestart` the winbar keeps the outline the stopped server sent, and when a symbol request was in flight the restarted server is never asked for the same text, so the old symbols stay until the next edit. Four places decide which windows get a winbar, three of them comparing the `never` and `always` literals, and `SplitWindow` gives a split count one row more for a winbar the new window never shows when it is split from a scratch window.

## What Changes

- `:LspRestart` drops the held symbols and the record of the text last asked, so the restarted server is asked again at the first idle tick once it is ready, and nothing answered before the restart reaches the outline.
- `TabPage` becomes the one place that compares the breadcrumbs modes: `winbar?` and a new `winbar_with?` (whether winbars show with a given count of file windows), which `SplitWindow` calls instead of restating the rule.
- `ArrangeView` decides which windows show a winbar and records it on each window (`Window#winbar`); `FramePresenter` paints the winbar of each window so marked instead of deciding again.
- A split count from a scratch window that keeps showing the scratch buffer counts its text rows without a winbar row, under `always` too; one that opens a file gets its winbar and the count of text rows below it.
- `SymbolOutline`'s comment says names are cut to 40 bytes, as `ControlText.strip` does.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `breadcrumbs`: a split count from a scratch window, and the outline after `:LspRestart`.

## Impact

- `carat/adapters/json_rpc_language_gateway.rb` (`restart`), `carat/domain/symbol_request.rb` (`forget`), `carat/adapters/symbol_outline.rb` (comment).
- `carat/domain/tab_page.rb`, `carat/domain/window.rb`, `carat/use_cases/arrange_view.rb`, `carat/use_cases/windows/split_window.rb`, `carat/adapters/frame_presenter.rb`.
- `test/editor_breadcrumbs.rb`: the restart row, the scratch split rows, and `winbar_with?`.
- `docs/codebase-map.md`.
- README.md: unchanged, the winbar and `:LspRestart` already read as they behave after this change; the fixes restore what it says.
- docs/architecture.md: unchanged, section 5 names `ArrangeView` as the use case reserving the winbar rows, which it stays.
- CLAUDE.md: unchanged, no command, agent, workflow, or rule changes.

Roadmap: part b of the queue's top-rows item, the winbar (`docs/architecture.md` section 12's breadcrumbs follow-up), a user now-request.

## Out of scope

- A per-window rule for slot or plugin windows beyond the scratch test they already get; the symbol request kinds other than document symbols, which `stop` already forgets.
- `PinHover`, which splits with a count and then loads a scratch documentation buffer into the new window, so its count still gets a winbar row the window never shows: fixing it needs `SplitWindow` told the new window will be scratch, a signature change across five callers, left for the backlog.
- Asking for symbols only when the layout window itself has a winbar: the gateway keeps asking while the tab shows winbars (`TabPage#winbar?`).

Assumptions recorded here instead of asked: the brief's first finding no longer holds as written on main, since `stop` clears the symbol request in flight through `forget_server` (the last check of `test/editor_breadcrumbs.rb` proves it); the defect it names is that the record of the text last asked and the held symbols survive the restart, which is what this change fixes. "A scratch split has its row" is read as: a split count from a scratch window gives the new window the rows the count names, its winbar row added only when the new window shows a file.
