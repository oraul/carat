# Design

## Context

The completion popup (`completion` change) shows a `CompletionPort` source's candidates: `ShowCompletion` opens it after a typed character when the source is ready, and the `keymap.completion` layer, consulted first by `HandleKey` while the popup shows, binds Ctrl-N, Ctrl-P, the arrows, Enter, Tab, and Esc. With no popup, Ctrl-N and Ctrl-P are unbound in insert mode. The only production source is the language server (`ServerCompletions`).

## Goals / Non-Goals

Goals: Neovim's keyword completion order for Ctrl-N and Ctrl-P over the listed buffers, shown in the same popup with the same keys; a bounded scan; no change to the per-key cost of typing (`insert` scenario held at its recorded allocations).

Non-goals: a second popup kind, inserting on selection, the `complete` option, a new port.

## Decisions

- Word completion is not a `CompletionPort` source. The port's source is asked on typing and its answer filtered fuzzily; keyword completion is asked by a key and keeps the scan's order. A use case, `CompleteWord#call(state, forward)`, run by the actions `completion.keyword_next` and `completion.keyword_previous` (`CompletionHandler` variants), fills the `CompletionMenu` directly with `fill`, sets the matches in found order, selects the first (forward) or last (backward) row, and opens the popup.
- The popup float drawing (`reopen`, the row offset, the rows, the label fitting) moves from `ShowCompletion` into a use case, `OpenCompletionPopup#call(state, typed_width)`, which `ShowCompletion` and `CompleteWord` both call (section 5: shared logic that needs other use cases stays a use case the others call). It now selects the menu's `selected` row and moves the popup window's cursor to it, as `SelectCompletion` does, so a Ctrl-P popup opens on its last row scrolled into view. `ShowCompletion`'s path with no popup is unchanged, so typing still allocates nothing.
- The scan is a domain record, `BufferWords` (prefix, found words, byte budget): `collect(buffers, current, row, start, forward)` walks the current buffer from the word being completed (start byte `start` on `row`): forward, the rest of its row, the rows below, the rows above from the top, then the start of its row; backward, the exact reverse. Then each other listed buffer that is not a scratch buffer, in list order after the current one, top to bottom forward or bottom to top backward. Within a slice of a line a backward scan walks the bytes from the end, so no per-line array is built. A word start is a word byte not preceded by one (`FuzzyMatch.word_byte?`, the definition `ShowCompletion` uses for the word before the cursor); a match starts with the prefix's bytes, is longer, and is kept unless already found (a linear check over at most 200 words).
- Bounds: the scan stops at 200 words (`CompletionList::LIMIT`, so nothing found is dropped by the list) and after 1,000,000 bytes read; the budget is charged per line slice before it is read, and a slice longer than what is left is cut, so one long line cannot exceed it.
- An empty typed part lists every word. `ShowCompletion` closed the popup on an empty typed part after every key; it now keeps a showing popup when the word is the menu's word and both typed parts are empty, which only `CompleteWord` produces. A server popup emptied by Backspace still closes, since its typed part was not empty.
- No match reports `Pattern not found` (Neovim's message for a failed keyword completion) through the `Outcome`, as an error, the text and mode unchanged.
- The actions join the insert session like any insert-mode action and record nothing in `LastChange`; accepting a word goes through `AcceptCompletion`, which notes the inserted text, so the dot command repeats the result, not the scan.
- Documentation: `ShowCompletionDocs` asks the source for the selected candidate's documentation with the menu's origin list; `ServerCompletions` answers "" for a list that is not its request's, so a word popup shows no documentation float and records no pick.

## Risks / Trade-offs

- [A buffer of many short lines spends the budget per line] → the budget counts bytes read, and 1 MB of text is scanned in milliseconds in compiled code; matches past it are not offered, which the no-match message reports.
- [The fuzzy re-ranking after typing more characters reorders the found order] → the matches still all start with the old typed part; keeping Neovim's order while filtering is left out, recorded in the proposal.
- [Moving the popup drawing changes `ShowCompletion`'s readers] → `test/adapters_assembly.rb` reads the float use cases through `OpenCompletionPopup` and checks they are the shared instances.
