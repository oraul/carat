# Design

## Context

Insert mode types through `HandleKey#insert_literal` into `InsertText`, and its actions (Enter, Tab, Backspace, the arrows, Esc) are `keymap.insert` bindings dispatched by `Dispatcher`, which joins the insert session's transaction (edit-path scout pack). Ctrl-N and Ctrl-P are unbound in insert mode. Floats exist (`FloatLayer` on the tab page, placed by `ArrangeView#place_floats` at the cursor for the "cursor" anchor, painted by `FramePresenter#paint_floats` with a float key that repaints the rows a changed box covers); the `Pmenu` groups are themed but unused (rendering scout pack). The language client sends no request and receives no response yet (language-services scout pack); `completion-request` adds that.

## Goals / Non-Goals

**Goals:**

- The popup, its matching, its keys, and its edit, over a source port that a double drives in the tests and the server drives in `completion-request`.
- No allocation per typed key when no popup shows and the source is not ready; `insert` held at 35.0.
- Completion text made safe and bounded where it enters the editor.

**Non-Goals:**

- The server request, its debounce and cancellation; documentation beside the list; word completion; snippets.

## Decisions

### A source port that never waits

`Ports::CompletionPort` has `ready?(buffer)` and `candidates(buffer, row, col)`, answering a `Domain::CompletionList` it holds now. The contract is non-blocking: a server source answers what its last response held and asks again in the background (`completion-request`). `EditorAssembly` takes the source as a keyword, `completions:`, as it takes the other ports: `bin/carat.rb` passes `Adapters::ServerCompletions`, never ready until `completion-request`, and `EditorHarness` passes `Doubles::FixedCompletions`, ready once a test adds candidates, so the other editor tests and the benchmarks run with no ready source. Alternative: a method on `LanguageServicePort`; the gateway would then be the only source and the popup could only be tested through a fake server process, which is `completion-request`'s work.

### The popup is a float

The popup is a `FloatWindow` over a buffer of formatted rows, anchored at the cursor with no border at z 1000, opened through `OpenFloat` and closed through `CloseFloat`. So placement, clipping, z order, and the float key's repaint of the rows it covered come with it. A change to the rows closes the float and opens a new one; a change of selection only sets the float's `selected` row and its window's cursor (so `ArrangeView` scrolls it). `FloatWindow` gains the member `selected`, -1 for a float that is no menu; `paint_float_row` fills a menu's rows with `Pmenu`, its selected row with `PmenuSel`. The float key gains the window id and the selected row (stride 10): the window id makes a float reopened at the same box repaint (the backlog fix), the selected row repaints a moved selection. The buffer is a scratch buffer owned by `:completion`, a name no plugin can have, so no plugin may close or move it.

Rows are " " icon " " label padded to the label column, two spaces, the detail padded to its column, " ". The label column is the widest label up to 40 cells, the detail column the widest detail up to 30, cut by display width at a character boundary. The spec's column offset puts the label under the word's first character; `FloatWindow#place` moves the box in at the screen's edges. The row offset is 1, or minus the height when the rows below the cursor are fewer than the height and fewer than those above.

### A keymap layer, consulted only while the popup shows

`Mode::COMPLETION` is a keymap layer, never the editor's mode: `keymap.completion <keys> <action>` lines bind it. `HandleKey#step` looks a key up there first when the mode is insert, the popup shows, and no keys are pending; a single-key match dispatches it like an insert action, anything else continues to insert mode's keymap. With no popup the check is one predicate and no lookup. Alternative: make the insert actions check the popup; it would spread the popup through every handler and hard-code which keys it takes.

### One refresh use case, called only when it can matter

`ShowCompletion#call(state, typed)` is called by `insert_literal` after a typed character (`typed` true) and at the end of `HandleKey#call` when the popup shows. Without a popup it returns at once unless typed and the source is ready, before any allocation. Otherwise it reads the word before the cursor by bytes (word bytes: ASCII letters, digits, underscore, and every byte of 0x80 or more), closes the popup when the mode is not insert or the word is empty, asks the source again when a typed character starts another word, closes the popup when any other key leaves the word (a cursor key, `<PageDown>`, or a buffer switch to another row or buffer), keeps the popup when the typed part is unchanged (so a selection moved by Ctrl-N survives the refresh), and otherwise filters, sorts, and reopens. `SelectCompletion`, `AcceptCompletion`, and `CloseCompletion` are the other three actions' use cases, registered by `CompletionHandler`; the state of the popup is `Domain::CompletionMenu`, built once in `EditorAssembly` and shared.

### Matching by anchored parts

`FuzzyMatch.score(pattern, word)` answers -1 or a score. The pattern is cut at underscores into parts; each part takes the earliest part start of the word after the previous part's anchor whose letter matches its first letter, and its other letters follow as a subsequence from there; since a later anchor leaves fewer letters, the earliest valid anchor is the only one to try. Letters match ignoring ASCII case. The score adds 1000 for a label that starts with the pattern, 2 per letter matched right after the one before, and subtracts the label's length; the sort is a stable insertion sort by score over at most 200 candidates.

### Safe text at the boundary

`CompletionItem.from_source` builds every candidate the menu keeps: `ControlText.plain` drops whole escape sequences (ESC `[` parameters and a final byte; ESC `]`, `P`, `X`, `^`, `_` up to BEL, ESC `\`, or the C1 ST; ESC and one character; U+009B and U+009D as ESC `[` and ESC `]`) and then cleans as `ControlText.line`, cut to the bound. An unterminated string sequence drops the rest of the text. The raw text is first cut to 4096 bytes so a hostile megabyte costs no more than that.

### The edit and the session

`AcceptCompletion` replaces the charwise range from the word's start to the cursor (Enter) or to the end of the word's characters after the cursor (Tab) with `Buffer#replace`, inside the insert session's open transaction, and notes in `LastChange` one `insert.backspace` per typed character taken out, one `insert.delete` per character after the cursor, and the item's text, so the dot command replays the same edit and the `.` register reads as the line does.

## Risks / Trade-offs

- [Reopening a float per filtering key allocates a buffer, a window, and the rows] → only while the popup shows; the popup is at most ten rows of bounded text.
- [The production source is never ready] → the editor shows no popup until `completion-request`; the tests cover the popup through the double.
- [The fuzzy rule is ours] → the anchored-parts rule is stated in `docs/compatibility.md` and tested by table.
- [Esc closes only the popup] → recorded as a difference from Neovim in `docs/compatibility.md`.
