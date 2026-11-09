# Proposal

## Why

A message on the message row is gone at the next key and nothing keeps it, so an error that flashed by while typing cannot be read again; asynchronous news from a language server (`window/showMessage`) is dropped, and long work such as indexing shows only a percent inside the `lsp` slot, with no title. The user's order puts `feedback` (queue item 1, T5 roadmap UI) first: messages and notifications. This change is outside the numbered roadmap of `docs/architecture.md` section 12, which ends with the plugin and release items; it belongs to the UI track the user approved after the floats (`floating-windows`, `layout-slots`, `breadcrumbs`).

## What Changes

- A message history: every one-line message shown on the message row, informational or error, and every notification is kept, the oldest dropped past 500 entries, as Neovim's `messagesopt` history.
- `:mes[sages]` shows the history (one line on the message row, several as a listing with the hit-enter prompt); `:messages clear` empties it. The output of `:messages` and other listings is not kept.
- Notifications: a box at the top right of the screen, below the buffer tabs, at most three stacked, the oldest replaced by a fourth, each expiring after 3 (info), 5 (warning), or 8 (error) seconds; its severity is the title on its top border in the severity's diagnostic group. A language server's `window/showMessage` is the first source.
- A progress segment on the status bar for long work: the work's title and message and a ten-cell bar of the percent, moving one step per report when the work gives no percent; with `option.reducedmotion true` such a bar is left out instead of moving. A language server's `$/progress` is the first source; the segment goes when the work ends or the server stops.
- `NO_COLOR` (set and not empty): notification boxes and the progress bar draw ASCII glyphs (`+`, `-`, `|`, `#`) in the `Normal` and `StatusLine` groups, with no severity color, as the start screen does.
- `docs/compatibility.md` gains a Messages and notifications table: a row per message kind and notification for its placement, expiry, and history, and the `:messages` rows.

Assumptions: the history keeps 500 entries (Neovim's default); a notification's text is cut to one line of at most 200 bytes; notifications never animate, so `reducedmotion` changes only the progress bar; the progress segment follows the current buffer's server; `window/logMessage` and `window/showMessageRequest` are not shown (the request keeps its "not supported" reply); a plugin notification request is left for a later change (plugin API version bump).

## Capabilities

### New Capabilities

- `messages`: the message history, `:messages`, and notifications with their placement, stacking, expiry, and plain drawing.

### Modified Capabilities

- `status-bar`: adds the progress segment, its priority, and its drawing under `reducedmotion` and `NO_COLOR`.
- `language-server`: `window/showMessage` becomes a notification and `$/progress` titles and messages fill the progress segment.

## Impact

- Domain: new `MessageHistory` and `Notices` records; `EditorState` keeps the history and records in `show`; `StatusSlots` holds the progress.
- Use cases: new `MessagesCommandHandler` (`:messages`), registered after the language server commands.
- Adapters: `FramePresenter` paints the notification boxes through the float key, `StatusBar` the progress segment, `InputController` expires notifications on idle reads, `JsonRpcLanguageGateway` reads `window/showMessage` and the progress titles, `EditorAssembly` wires the one `Notices`.
- Docs: `docs/compatibility.md`, `docs/codebase-map.md`.
- Out of scope: a plugin API notification or progress request, `:{count}messages`, colored `:messages` lines, `window/showMessageRequest` choices, notification history beyond the shared message history, and dismissing a notification by a key.
