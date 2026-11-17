fix(search): read ~, a second caret, and collections as neovim does

## Summary

Fixes four search bugs: incsearch now keeps the cursor on a character, `~` in a search pattern matches the last substitute's replacement string, a second caret after an anchoring one is read as a literal caret, and a collection that holds the delimiter no longer cuts the typed pattern short. Each of these differed from Neovim: `/$` previewed past the line end, `~` answered E33 after a substitute, `^^` never matched a caret, and `/[\]/]` was cut at the slash inside its collection. This is part a of the backlog item, split at its start into three parts; the performance part and the tidy part stay in the pool as `motions-search-tidy-b` and `motions-search-tidy-c`.

---

## Changes

- Fix incsearch so the cursor sits on the match clamped to the last character of its line, the column Enter then lands on
- Change `~` in a `/` or `?` pattern and in a `:g` or `:v` pattern to match the previous substitute's replacement string, answering E33 only before any substitute, with `:set ic` and `:set scs` recompiling the last search pattern with that string
- Fix a `^` right after an anchoring `^` so it matches a literal caret
- Refactor the prompt's search for the end of the pattern to use the compiler's own collection scan (`VimPattern.collection_close`), so a `\]` or a leading `]` in a collection no longer ends the pattern at a `/` inside it
- Refactor the split of a typed search into pattern and offset into `DelimitedPattern.typed`, and the prompt character into `SearchPrompt.prefix_of`, each written once and used by both `FindMatch` and `PreviewSearch`
- Add rows to `test/editor_search.rb`, `test/editor_global.rb`, and `test/domain_vim_pattern.rb` for the incsearch clamp, `~` with and without a previous substitute, `^^`, and where the pattern ends for each collection form, with their snapshots
- Add the search spec requirements for these cases, and document them in the README patterns line, the compatibility pattern paragraph and its Differences from Neovim paragraph, and the code map entries
- Record the backlog-lane queue, its metrics history row, and the planner's carried backlog entries in `docs/findings/motions-search-tidy.md`

---

## Testing

- Run the security review of the committed diff at 57b06cecdda1, pass with no high, medium, or low findings
- Run the checker's stages at 57b06cecdda1 (docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, tools-test, gates, metrics), all pass
- Run the quality review at 57b06cecdda1, pass with no blocking finding and one advisory, and the benchmark review, pass
- Run make spec-validate after archiving the change, all 53 items pass
- Run make docs-lint, make gates, and the pr-body gate on the packaged branch, all pass

---

## Notes

The `~` string is the one in effect when the pattern was compiled, so `n` after a later substitute keeps the earlier string until the pattern is typed again or recompiled by `:set ic` or `:set scs`; Neovim reads the current string on every use, and the compatibility doc now lists this difference. The quality advisory about the four `compile_search` calls that each unpack `LastSubstitute` is a style suggestion and was dropped, not carried. The incsearch budget per key, the sentence-motion rescan, the ASCII length charge, the one-character slices, the motions' whole-state parameter, the noh row, and the sweep tidy items are left to `motions-search-tidy-b` and `motions-search-tidy-c`.
