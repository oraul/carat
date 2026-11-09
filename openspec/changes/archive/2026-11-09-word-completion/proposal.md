# Proposal

## Why

Without a language server, or in a buffer whose server does not complete, insert mode offers no completion at all: Ctrl-N and Ctrl-P, Neovim's keyword completion, do nothing unless the server's popup is already open. Completing a word from the words already in the open buffers is the most used completion in Neovim and needs no server. This continues roadmap item 10, `language-services` (completion menu), in `docs/architecture.md` section 12, as a user request (docs/queue.md, word-completion).

## What Changes

- In insert mode with no completion popup open, Ctrl-N completes the word before the cursor from the words of the listed buffers, scanning forward from the cursor through the current buffer (to its end, then from its top back to the cursor), then every other listed file buffer after it in list order, top to bottom. Ctrl-P scans the same buffers backward: the current buffer from the cursor up to its top, then from its end back to the cursor, then the other buffers, each from its last line up.
- A word is a run of letters, digits, underscores, and bytes of 0x80 or more, the same as the popup's word before the cursor; a match starts with the typed part, case sensitive, is longer than it, and is listed once, where it is first found; the word being completed is not a match.
- The matches show in the existing completion popup, in the order found: with Ctrl-N the nearest forward match is the first row and selected; with Ctrl-P the nearest backward match is the last row and selected, the farther ones above it. Then the popup's own keys apply: Ctrl-N and Down move down, Ctrl-P and Up move up, wrapping; Enter puts the selected word over the typed part, Tab over the whole word; Esc closes; typing filters as it does for a server's candidates.
- With no word before the cursor every word of the buffers is a match, as in Neovim.
- With no match, the message row reads `Pattern not found` as an error, and nothing changes.
- The scan is bounded: at most 200 matches (the popup's list limit) and at most 1,000,000 bytes of text read per press.
- With the language server's popup open, Ctrl-N and Ctrl-P keep moving its selection: the completion layer answers first, as today.
- New bindings `keymap.insert <C-n> completion.keyword_next` and `keymap.insert <C-p> completion.keyword_previous`; no cost per key otherwise: typing still makes no allocation without a popup.

Out of scope: inserting the selected match into the text as the selection moves (Neovim's default `completeopt`; the existing popup inserts on Enter or Tab), the original text as a stop in the cycle, the `-- Keyword completion (^N^P) match 1 of 3` mode message, `ignorecase` and `infercase`, the `complete` option's other sources (unlisted buffers, tags, included files, dictionaries), and `iskeyword`.

Assumptions: other listed buffers are scanned in list order after the current one in both directions, each in the direction of the key (Neovim's order for buffers in other windows versus hidden ones is not reproduced); scratch buffers (explorer, prompts) are not scanned; the byte bound is charged per line slice read, so a single long line is cut at the bound; the popup keeps its fuzzy re-ranking once more characters are typed after the popup opened.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `completion`: keyword completion with Ctrl-N and Ctrl-P from the buffers' words in insert mode with no popup open, its order, its bounds, and the no-match message.

## Impact

- New: `carat/domain/buffer_words.rb` (`BufferWords`), `carat/use_cases/completion/complete_word.rb` (`CompleteWord`), `carat/use_cases/completion/open_completion_popup.rb` (`OpenCompletionPopup`, the popup float drawing moved out of `ShowCompletion` so both use it), `test/editor_word_completion.rb`.
- Changed: `ShowCompletion` (draws through `OpenCompletionPopup`; keeps an open popup whose typed part is empty), `CompletionHandler` (two actions), `EditorAssembly`, `config/default.caratrc` and its generated mirror, `test/adapters_assembly.rb`, `test/editor_completion.rb` (the no-source Ctrl-N check now opens the word popup).
- Docs: `docs/actions.md`, `docs/compatibility.md`, `docs/codebase-map.md`, `docs/architecture.md` (section 5.1), `README.md` if it lists insert keys, `docs/backlog.md` (the plan notes).
