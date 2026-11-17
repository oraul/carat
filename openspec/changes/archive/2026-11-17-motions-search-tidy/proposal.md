# Proposal

## Why

Part a of the backlog queue's `motions-search-tidy` item, split at its start by the planner (14 entries in three independently testable parts): the search correctness bugs. While typing `/$` with `incsearch` on, the cursor is left on the line break past the last character (`carat/use_cases/search/preview_search.rb:56`), a column normal mode never allows. `~` in a `/` or `?` pattern answers E33 even after a substitute, where Neovim matches the last replacement string (`carat/domain/vim_pattern.rb:394`). A second `^` right after an anchoring one is read as another anchor instead of a literal caret (`vim_pattern.rb:260`). The prompt finds where the pattern ends with its own collection scan (`vim_pattern.rb:120`), which differs from the compiler's (`:556`): `\]` inside `[...]` ends that scan, so `/[\]/]` is cut to `[\]` with `]` read as an offset. The cut of the typed pattern and its `/` or `?` prefix are written in both `FindMatch` and `PreviewSearch`.

## What Changes

- incsearch puts the cursor on the match clamped to the last character of its line, as Enter then does, so `/$` previews on the last character.
- `~` in a `/` or `?` pattern, and in a `:g` or `:v` pattern, matches the previous substitute's replacement string, and answers E33 only when no substitute has run, as in Neovim. `:set ic` and `:set scs` recompile the last search pattern with it too.
- A `^` right after an anchoring `^` is a literal caret, so `^^` matches a caret at the start of a line.
- The prompt's pattern end and the compiler share one collection scan (`VimPattern.collection_close`), so a `\]` or a `]` first in a collection no longer ends the pattern at a `/` the collection holds.
- The cut of a typed search into its pattern and offset is `DelimitedPattern.typed`, and the prompt character `SearchPrompt.prefix_of`, each written once and used by `FindMatch` and `PreviewSearch`.
- Tests: `test/editor_search.rb` rows for the incsearch clamp, `~` after a substitute, and the escaped bracket at the prompt; `test/domain_vim_pattern.rb` rows for `^^`, `~` with and without a previous string, and the pattern end of the collection forms.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `search`: adds the requirements that incsearch keeps the cursor on a character and that `~`, a second `^`, and a collection holding the delimiter read as in Neovim.

## Impact

- `carat/domain/vim_pattern.rb`, `carat/domain/delimited_pattern.rb`, `carat/domain/search_prompt.rb`, `carat/domain/last_search.rb`, `carat/use_cases/search/preview_search.rb`, `carat/use_cases/search/find_match.rb`, `carat/use_cases/search/global_command.rb`, `carat/use_cases/ex/set_command_handler.rb`, `carat/adapters/editor_assembly.rb`.
- Tests: `test/editor_search.rb`, `test/domain_vim_pattern.rb`, `test/adapters_assembly.rb` when it builds the touched use cases, with their snapshots.
- README.md: changed, the patterns line names `~` as the last substitute's replacement string.
- docs/architecture.md: unchanged, it names `PreviewSearch` and `VimPattern` only by role, which stays.
- CLAUDE.md: unchanged, no process change.
- docs/compatibility.md: changed, the pattern paragraph and the substitute differences no longer say `~` in a search answers E33 after a substitute, and say a second `^` is literal.
- docs/codebase-map.md: changed, the entries of `VimPattern`, `DelimitedPattern`, and `SearchPrompt` name their new class methods; no file is added, moved, or removed.
- docs/actions.md: unchanged, no action is added.

Outside the roadmap of `docs/architecture.md` section 12: a backlog tidy-up (T6 with correctness bugs) of sprint 15.

Backlog headings this change covers: "### Incremental search leaves the cursor past a line end (sprint-14 sweep quality)", "## ~ in a search pattern ignores the last substitute", "## A second caret after the start of a pattern is read as an anchor", "## The search offset is found by a collection scan that differs from the compiler's", "## The pattern-source cut and the prompt prefix are written twice". The other nine headings stay in the backlog under the pool items `motions-search-tidy-b` (performance) and `motions-search-tidy-c` (tidy).

## Out of scope

- The incsearch budget per key, the sentence-motion rescan and its bench row, the ASCII length charge, and the one-character slices (`motions-search-tidy-b`).
- Motions taking the whole `EditorState`, the `:noh` row, and the sweep tidy items (`motions-search-tidy-c`).
- Search offsets, which still answer Not implemented.

Minor assumptions: `~` takes the replacement string as it was when the pattern was compiled, so `n` after a later substitute keeps the old string until the pattern is typed again or recompiled by `:set ic`; Neovim recompiles on every use, a difference too small to carry. `:g` and `:v` get `~` too since they compile the same search pattern and already hold the last substitute. The clamp uses the prompt's own mode, the last character, also for a search started in a visual mode, which Enter then places by its own rule.
