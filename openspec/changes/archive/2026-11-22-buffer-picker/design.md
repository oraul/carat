# Design

## Context

The finder plugin (`carat/plugins/finder/plugin.rb`) is one picker with two sources today: the file listing (`list_files`) and the grep index built over it. It keeps its state on the instance (`@paths`, `@matches`, `@selected`, `@grep`) and `close` clears it. A plugin sees the editor only through `PluginApi::Host`; no request lists the buffers, and a plugin is activated on its first trigger (API 2.9) with no events replayed, so the finder cannot build a buffer or recent list from `buffer_open` events alone. The core's buffer list is `Domain::BufferList`; a buffer a window starts showing passes through `BufferList#load` (from `enter`, so every `:e`, `:b`, pick, and jump) or, when `:bd` closes a buffer tab, `withdraw`.

## Goals / Non-Goals

**Goals:**
- Three pickers on the existing float, prompt, and keys: buffers, recent files, resume.
- Two read-only host requests, by the API's rule (a `Host` method, a `PluginLink` override, a family method, a minor bump).

**Non-Goals:**
- Persisting the recent list across runs, a buffer preview of unsaved text, sorting by last use (proposal, Out of scope).

## Decisions

- The recent list lives in the core, in `BufferList` as a pinned `recent` member (`Array[String]`), recorded right after `Window#show` in `load` and `withdraw`, and kept after `remove`; not in `add`, which also lists again a modified buffer a plugin's `open_file` replaced (`WindowRequests#open_file`) without showing it. The alternative, the finder recording `buffer_open` events, misses every file opened before the finder's first use (activation on first trigger), so `<leader>fr` would be empty on its first press. Recording on show (not on `remove`) gives "recently shown", which is what a user picking a file just left expects; a buffer already first is not moved, so repeated loads cost one comparison. Bounded at `RECENT_LIMIT = 100`: dropping the last entry keeps the array within a page of strings.
- Paths are the buffer's own `path_text`, the string `:ls` shows and `open_file` resolves, so a picked path reaches the same buffer (`WindowRequests#open_file` compares with `same_path?`).
- `list_buffers` answers the listed file buffers (`!tabless?`, a path) in list order; `recent_files` copies the recent array. Both go in `BufferRequests`, which already holds the buffer list, and answer `Response.listing` with copied strings (`Boundary.copied_lines`).
- The finder gets a `@source` symbol (`:files`, `:grep`, `:buffers`, `:recent`) in place of the `@grep` flag, which every grep branch reads as `@source == :grep`; `open(host, source, query)` lists by source and opens the live prompt on the query, so the resume is the same open with the remembered query. The title is `TITLES` by source with the counts.
- Resume: `close` remembers the source, the query (kept in `@query` by `filter`, so a split or tab pick, which arrives without the prompt's text, remembers it too), and the highlight; `<leader>fR` reopens the source with them, the list read again and the highlight clamped to the matches. Reading again was preferred to keeping the closed list: a buffer deleted since would otherwise be offered and fail to open.
- The preview path is `Paths.absolute(root, path)`, so a buffer or recent path given absolute (a file outside the project) previews too; for the file listing, relative and never holding `..`, it is the joined path as before.

## Risks / Trade-offs

- [The recent list shows a file deleted from the disk since] → picking it opens a new buffer for the path, as `:e` does; the list is a session's history, not a disk listing.
- [A relative path recorded before a `:cd` names another file after it] → the buffer list has the same property for `:ls`; recorded as a follow-up with the persisted list.
- [Grep resume reads every file again] → the same cost as `<leader>fg`, bounded by the grep index's limits.
