# Backlog: carat/domain/fuzzy_match.rb

## Fuzzy completion matching reuses letters and matches a word of underscores

- Where: `Carat::Domain::FuzzyMatch` in `carat/domain/fuzzy_match.rb` (line 32 at 334d899), where each part's anchor is searched only after the previous part's anchor. Quality advisory in `completion`.
- Why it matters: a later part can reuse letters the previous part already matched, so `fa_a` matches `file_a` with one `a`, and a typed word of only underscores matches every candidate, which fills the popup with noise.
- Fix outline: start the next part's anchor search after the previous part's last matched byte and answer -1 when the pattern has no letters, with a table row for each in `test/domain_fuzzy_match.rb`.
- Also: test/domain_fuzzy_match.rb
- Category: editor
- Added: 2026-11-07

### carat/domain/fuzzy_match.rb:48 positions duplicates the score walk

Duplication: positions repeats score's part loop and follow's inner walk byte for byte, so the two can drift apart. Fix: one private walk that fills an optional positions list and returns the runs, score and positions both calling it.
- Category: editor
- Added: 2026-11-14

### carat/domain/fuzzy_match.rb:69 positions matches multibyte queries by byte

Correctness, pre-existing and outside this change's fix: positions compares bytes, so a multibyte query's continuation bytes can match inside another character and FollowPalette#mark then paints that character ("日" on "本語日" matches E6 in 本 and 97 A5 in 日, marking both). Fix: step the word by whole characters (Domain::Utf8.size_at) and compare each query character's bytes as a unit, with a FuzzyMatch test of such a word.
- Category: editor
- Added: 2026-11-14
