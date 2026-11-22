# Proposal

## Why

Moving between the file finder and the grep picker loses what was typed: the picker is closed and the other opened on an empty prompt. Grepping for the word under the cursor, the commonest grep, needs the word typed again. The change is the feature queue's `finder-switch` item, a user request.

## What Changes

- Add the `plugin.finder.switch` action, bound to `<C-g>` in the finder prompt's keys: it closes the open picker and opens the file picker from the grep picker, or the grep picker from the file, buffer, or recent picker, with the text typed so far on the prompt, the list filtered by it, and the highlight on the first row.
- Add the `plugin.finder.word` action, bound to `<leader>fw` in normal mode: it opens the grep picker with the word under the cursor on its prompt, read through the existing `read_buffer` request, or with the empty prompt when the cursor is on no word.
- Add `Matcher.word_at(line, col)`, the word of a line at a code point column: the run of letters, digits, underscores, and multi-byte characters around it.
- Document both in `docs/actions.md`, `docs/compatibility.md` (File finder), `docs/plugins.md`, the code map, and the README.

No API change: both use `live_prompt`, `close_prompt`, and `read_buffer` as they are, so `carat/plugin_api.rb` and its version stay.

Assumptions: the word under the cursor is the keyword run around the cursor only (Neovim's `<cword>` also takes the next word to the right when the cursor is on a blank; this does not, so a blank gives the empty prompt as the queue entry says); a multi-byte character counts as a word character whatever it is, as the grep picker's whole-word match already counts it; a word that is not valid UTF-8 gives the empty prompt; `<C-g>` from the buffer or recent picker opens the grep picker, since the item names only the files and grep pickers and one rule serves every source; the switch records the picker it left as the one to resume only until the new picker closes, which then records itself; `<C-g>` had no binding in the command line, so the prompt's key shadows nothing.

## Capabilities

### New Capabilities

### Modified Capabilities
- `file-finder`: the switch key of the prompt and the word-under-the-cursor grep.

## Impact

- Code: `carat/plugins/finder/plugin.rb`, `carat/plugins/finder/matcher.rb`.
- Tests: `test/editor_finder.rb`, `test/plugins_finder_matcher.rb` and their snapshots.
- Docs: `docs/actions.md`, `docs/compatibility.md`, `docs/plugins.md`, `docs/codebase-map.md`, README.md.
- docs/architecture.md: unchanged, it describes the plugin host and the API, which this change leaves alone.
