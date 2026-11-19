## Why

The file finder (`<leader>ff`) accepts any path that holds the typed letters in order: for `explorer` the path `ezzzxpzzzlzzzozzzrzzezrrr` is listed, scoring above `carat/plugins/explorer/plugin.rb`, because a skipped byte costs 2 points against 40 for a matched word-start byte, and the 256 points of a match inside the file name lift any scattered file-name match above a contiguous match in a directory (`tools/explain_pl_or_err.sh` ties `test/editor_explorer.rb`). The user reported it ("it shouldn't be ezzzxpzzzlzzzozzzrzzezrrr for example"). Outside the roadmap of `docs/architecture.md` section 12: a fix the user asked for, in the finder plugin.

## What Changes

- A path matches a term only as a contiguous case-insensitive (ASCII) substring (tier 1) or as at most four contiguous runs in order, each run after the first starting at a segment or word start (tier 2: initials such as `ep` and `fgr`, camel humps); a run that starts mid-word is no match, so scattered letters no longer match.
- Ranking: every substring match above every run match; among substrings the file name at a word start, the file name elsewhere, a directory at a word start, elsewhere; among run matches fewer runs first; then a shorter path, then listing order, as before.
- A query with spaces is several terms, each matching by those rules in any order; a path ranks by its worst term, then by the terms together. A query of only spaces lists every file in listing order, as the empty query does.
- `Matcher` stays allocation-free and keeps `key` and `index_of`; the scoring constants and functions of the subsequence match are replaced. The grep picker's `find`, `word_start?`, and `word_end?` are unchanged (`find` shares its loop with the new `find_in`), and `boundary?` serves both.

## Capabilities

### New Capabilities

### Modified Capabilities
- `file-finder`: the requirements Typing filters the files best match first and Matches are ranked best first.

## Impact

- Code: `carat/plugins/finder/matcher.rb` (the scoring), `carat/plugins/finder/plugin.rb` (`filter` lists a blank query in listing order); tests in `test/plugins_finder_matcher.rb`, `test/editor_finder.rb`, and their snapshots (the 10,000-file row counts the paths that hold `99` as a substring).
- Specs: file-finder (two modified requirements, their scenarios).
- README.md: changed, the finder's matching in the `<leader>f` line.
- docs/plugins.md: changed, a section on the finder's matching.
- docs/codebase-map.md: changed, the matcher's entry.
- docs/architecture.md: unchanged, no layer, port, API, or roadmap change; it names the fuzzy finder only as a plugin.
- docs/compatibility.md, docs/actions.md: unchanged, no Neovim command and no action is added or changed.
- Assumptions: at most four runs is "a few"; inside the file name, a hit at a word start ranks above one in the middle of the name, which keeps the existing order of `a` over `lib/alpha.rb` and `lib/beta.rb`; a query of only spaces is blank, not "no match"; the first run may start anywhere in the path, as the brief says only later runs start at boundaries.
