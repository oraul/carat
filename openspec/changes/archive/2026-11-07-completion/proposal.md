# Proposal

## Why

Carat has no completion: typing in insert mode never offers the names the language knows. This delivers the completion menu of roadmap item 10, `language-services`, in `docs/architecture.md` section 12 (docs/queue.md item 2, goal 2). The planner split the brief: this change is the popup, its matching, and its keys over a completion source port tested with a double; asking the language server through that port, debounced and cancelled when stale, is `completion-request`, next in the queue.

## What Changes

- Typing a word character in insert mode asks the completion source, when it is ready for the buffer, for the candidates of the word before the cursor, and shows those that match the typed part in a popup: a floating window under the word (above it when the screen has no room below), at most ten rows, each row the kind's icon by name, the label, and the detail or type on the right, the selected row in `PmenuSel` and the others in `Pmenu`.
- Matching is fuzzy: the typed part is cut at underscores into parts; each part's first letter starts a part of the candidate (its start, after an underscore or another non-word character, or a lower-to-upper case change) later than the previous part's, and its other letters follow in order, ASCII letters ignoring case, so `fn_na` finds `file_name`. Candidates whose label starts with the typed text come first, then by a score, then in the source's order.
- While the popup shows, a key is looked up first in a new keymap layer, `keymap.completion`, bound in `config/default.caratrc`: Enter inserts the selected item over the typed part (`completion.insert`), Tab replaces the whole word under the cursor with it (`completion.replace`), Ctrl-N and Down select the next row, Ctrl-P and Up the previous one (`completion.next`, `completion.previous`, wrapping), and Esc closes the popup and stays in insert mode (`completion.close`). Any other key goes on to insert mode as before, and the popup follows the typed part: typing and Backspace filter again, a word character no longer before the cursor, another line, another buffer, or leaving insert mode closes it.
- An inserted item is part of the insert session: one undo step with the typed text, repeated by `.`, and in the `.` register.
- Completion text is untrusted: every label, detail, and insert text drops whole escape sequences (CSI, OSC and other strings, two-byte escapes, their C1 forms), then every other control, has illegal bytes as U+FFFD, and is cut to a bound of bytes (label 80, detail 80, insert text 200); a kind outside the known names reads as `text`; a source's list is cut to 200 candidates.
- No cost while typing without a popup: when the source is not ready the typed key adds one call and no allocation, so the `insert` benchmark keeps 35.0 allocations per key; the production source is not ready until `completion-request` asks the server.
- Twelve completion kind icons join the icon table (`kind_text` to `kind_constant`).
- A float reopened at the same box repaints: the frame's float key carries the float's window id and its selected menu row, which fixes the backlog entry "A float reopened at the same box keeps the old float's text".

Out of scope: the language server request, its debounce and cancellation, and the failed-initialize fix (`completion-request`); the selected item's documentation (`completion-docs`); Ctrl-N and Ctrl-P completing buffer words without a popup (`word-completion`); snippets and text edits other than inserting the item's text.

Assumptions: the example `fn_na` finds `file_name` cannot be met by a plain subsequence (the pattern has two `n` letters, the name one), so each underscore part of the typed text is anchored at its own part of the name and its letters may run on past that part, the parts' anchors in order; a single part's first letter must start a part of the name, as most editors' fuzzy matchers ask. Esc closes the popup only, as in most IDEs, rather than also leaving insert mode as Neovim's does; a second Esc leaves. Ctrl-N and Ctrl-P move the selection without inserting the item, as with `completeopt=noinsert`. The production source is an adapter that is never ready until `completion-request`, so the editor shows no popup yet outside the tests.

## Capabilities

### New Capabilities

- `completion`: the completion popup in insert mode: when it opens and closes, what a row shows, the matching and the order, the keys while it shows, the edit an accepted item makes, and the limits on completion text.

### Modified Capabilities

- `floating-windows`: a float closed and replaced by another at the same box repaints its rows.
- `icons`: the table also holds the twelve completion kind names.

## Impact

- New: `carat/domain/completion_item.rb`, `completion_list.rb`, `completion_menu.rb`, `fuzzy_match.rb`; `carat/use_cases/completion/` (`show_completion.rb`, `select_completion.rb`, `accept_completion.rb`, `close_completion.rb`); `carat/use_cases/actions/completion_handler.rb`; `carat/ports/completion_port.rb`; `carat/adapters/server_completions.rb`; `carat/doubles/fixed_completions.rb`; `test/domain_fuzzy_match.rb`, `test/editor_completion.rb`.
- Changed: `ControlText` (escape sequences), `Icons`, `Mode` (the `completion` keymap layer), `FloatWindow` (a selected menu row), `FramePresenter` (menu groups, the float key), `HandleKey` (the layer and the refresh), `EditorAssembly`, `EditorHarness`, `bin/carat.rb`, `config/default.caratrc` and the generated default config, `docs/actions.md`, `docs/compatibility.md`, `docs/codebase-map.md`, `docs/backlog.md`.
