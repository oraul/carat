# Proposal

## Why

A user reading code cannot see what a method or constant under the cursor does without leaving the editor: the language server already knows (`textDocument/hover`), but nothing asks it. This delivers hover, part of roadmap item 10, `language-services`, in `docs/architecture.md` section 12 (docs/queue.md item 1, goal 2).

## What Changes

- `K` in normal mode asks the current buffer's language server for the documentation under the cursor; the answer opens at the next idle tick, with no key, in a bordered float below the cursor (above it when the room is there), at most 80 columns and 20 rows, with the markdown laid out as plain rows (headings, emphasis, code spans, and link markup taken out, list markers as bullets, quotes as bars, fenced code indented). A server with no answer shows `No information available`; a buffer whose server does not hover shows `No hover provider for this buffer`.
- `K` again while the float shows enters it, so every normal key scrolls the document (`j`, `Ctrl-D`, `G`); `Esc` closes it, and so does moving the cursor, switching buffer or window, or leaving normal mode in the window under it.
- `<leader>dp` (the new docs leader group) pins the shown documentation into a horizontal split holding a scratch copy, which stays when the float closes.
- The text is untrusted: escape sequences and controls are dropped, at most 16,384 bytes are read and 100 rows kept, nesting is capped at four levels, a list of contents is read up to 16 parts, and only the answer to the request in flight is read; a request unanswered two seconds past its sending is cancelled, and a new `K` cancels the one in flight.
- Wrapped markdown rows no longer break inside their own prefix (the two-space code indent, a bullet, or a quote bar), the backlog entry folded into this change; the completion documentation float gets the same fix.
- No cost per key while no hover float shows: one integer comparison.
- The initialize request advertises hover with markdown content.
- Docs: the map, actions, compatibility, README, and the backlog entries the plan names.

Out of scope, split into a follow-up recorded in `docs/backlog.md` (`quick-docs-styles`): colors inside the float and the pinned split (headings, emphasis, code spans, and fenced code through the syntax highlighter). The float paints one group, `NormalFloat` with its own background, and a syntax group has none, so per-span colors need a float layer of groups in the theme and the SGR table, a change to rendering as large as this one. Also out of scope: `keywordprg` (Neovim's `K` without a server runs `:Man`), a `q` key inside the float, and hover on visual selections.

Assumptions: the docs leader group is `d` and the pin key `<leader>dp`; the pinned split opens with the docs' rows as its height, at most 10, and takes the focus as `:split` does; a hover answer whose cursor moved before it arrived is dropped silently; a timed-out request shows no message.

## Capabilities

### New Capabilities

- `hover-docs`: the documentation under the cursor from the language server, its float, scrolling, pinning, closing, and the bounds on its untrusted text.

### Modified Capabilities

- `leader-keys`: a new docs group, `<leader>d`, whose `p` pins the hover documentation.

## Impact

- New: `carat/domain/hover_request.rb`, `carat/use_cases/docs/` (`RequestHover`, `ShowHover`, `FollowHover`, `PinHover`), `carat/use_cases/actions/docs_handler.rb`, `test/adapters_hover.rb`.
- Changed: `JsonRpcLanguageGateway` (hover request and answer, initialize capability, `waiting?`), `InputController` (the arrived answer at the idle tick), `HandleKey` (the per-key close check), `EditorAssembly`, `MarkdownText` (wrapping), `config/default.caratrc` and the generated default config, `test/domain_markdown_text.rb`.
- Docs: `docs/codebase-map.md`, `docs/actions.md`, `docs/compatibility.md`, `README.md`, `docs/backlog.md`.
