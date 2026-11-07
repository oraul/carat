# Proposal

## Why

The completion popup shows each item's label, kind, and type, but not what it does: a user choosing between `filter` and `final` cannot read their documentation without leaving insert mode. This delivers the documentation beside the completion menu, part of roadmap item 10, `language-services`, in `docs/architecture.md` section 12 (docs/queue.md item 1, goal 2), which `completion-request` left out.

## What Changes

- While the popup shows, the selected item's documentation shows in a second float beside the list, on its right (on its left when the right lacks the room), at the list's rows, wrapped to at most 60 columns and 12 rows; it follows the selection, moves with the list, and closes with it (Esc, accepting an item, no match, leaving insert mode). An item without documentation shows no float.
- The documentation comes from the completion answer when the server sent it there; otherwise, when the server advertised `resolveProvider`, it is fetched lazily with `completionItem/resolve` once the selection rests on the item for 0.1 seconds (it settles), at most one request per item of an answer and at most one in flight; moving through the list sends nothing for the items passed over, and a resolved answer opens the float at the next idle tick with no key.
- Markdown is shown as plain text: headings, emphasis, inline code, and link markup are taken out, list markers read as bullets, block quotes as bars, and fenced code is kept indented.
- The text is untrusted: escape sequences and controls are dropped, at most 16,384 bytes of a document are read, at most 100 rows kept, quote and list nesting is capped at four levels, and the resolve answer is read only for the request in flight.
- The initialize request advertises markdown documentation and lazy resolution of `documentation`.
- Docs: the map entries, the compatibility and README lines for the popup, and the backlog entries the plan names (11 new entries, four updated).

Out of scope: colors for headings and code inside the float (it is drawn in `NormalFloat`, one group per float), scrolling the documentation float, a `completeopt`-style option to turn it off, resolving other properties (`detail`, `additionalTextEdits`), and the `K` hover popup (`quick-docs`, which can reuse the markdown reader).

Assumptions: "styled" is read as the markup turned into plain layout (bullets, bars, indentation) in the float's own style, since a float paints one group; per-span colors come with `quick-docs`. The settle time is the completion debounce, 0.1 seconds, a constant. Plain-text documentation goes through the same reader, which only drops markup a plain text rarely holds. An item whose resolve was cancelled after two seconds is not asked again for that answer, which keeps the one request per item.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `completion`: the selected item's documentation beside the popup, fetched lazily from the server, untrusted and bounded.

## Impact

- New: `carat/domain/markdown_text.rb`, `carat/domain/completion_docs.rb`, `carat/use_cases/completion/show_completion_docs.rb`, `test/domain_markdown_text.rb`.
- Changed: `CompletionPort` (`documentation`), `ServerCompletions`, `FixedCompletions`, `CompletionRequest`, `CompletionMenu`, `ShowCompletion`, `CloseCompletion`, `JsonRpcLanguageGateway`, `InputController`, `EditorAssembly`, `carat.rb`, `test/editor_completion.rb`, `test/adapters_server_completions.rb`, `test/adapters_assembly.rb`, `docs/codebase-map.md`, `docs/architecture.md` (the port table), `docs/compatibility.md`, `README.md`, `docs/backlog.md`.
