# Backlog: carat/domain/search.rb

## The search budget charges a line's length on ASCII lines too

- Where: `Carat::Domain::Search.match_at` in `carat/domain/search.rb` (line 101), which charges every match tried its line's length as a fixed cost; the risk note at line 50 of the archived design of `buffer-search` and the Search rows of `docs/compatibility.md`. Quality advisory of `buffer-search` at a36858a2bc88.
- Why it matters: `docs/spinel-notes.md` implies the engine finds a code-point position without a scan on ASCII-only text, so the charge is needed only on other lines; as it is, `N` or `?` on a long ASCII line (minified code) with more than about 400 million divided by its length matches before the cursor stops with `E363`, a frame highlights only about 20 million divided by the length matches of such a line, and the design says only non-ASCII lines stop.
- Fix outline: compute `text.ascii_only?` once per line beside its length and charge the fixed cost only when it is false, with a `domain_search` row of a long ASCII line of many matches searched backward; or correct the risk note in the design and `docs/compatibility.md`. Queued in `search-tidy`.
- Also: docs/compatibility.md, docs/spinel-notes.md
- Category: editor
- Added: 2026-11-04

## The overridden-method RBS form is used for Regexp and MatchData methods

- Where: `carat/domain/search.rb:106` and `carat/domain/replacement.rb:87,152`, which use `# @rbs` parameter lines with the return in prose on methods that override nothing, because `MatchData` cannot be pinned; `CLAUDE.md` (inline RBS) and `docs/spinel-notes.md:39` reserve that form for overrides. Quality advisory at spinel-bump. Raised again at be4b63a.
- Why it matters: the documented rule and the code disagree, so the next reader either "fixes" the signature into one Spinel cannot analyze or copies the form where it is not needed.
- Fix outline: extend `docs/spinel-notes.md` line 22 or 39 to say a method taking or returning `Regexp` or `MatchData` gets parameter lines and its return in prose.
- Also: carat/domain/replacement.rb, CLAUDE.md, docs/spinel-notes.md
- Category: editor
- Added: 2026-11-10

### Match_at turns a RegexpError or ArgumentError from the engine into (sprint-20 sweep quality, search.rb:116)

- Location: `carat/domain/search.rb:116`
- Why: match_at turns a RegexpError or ArgumentError from the engine into budget.stop, so a pattern the engine rejects is reported as a search stopped by the budget
- Fix: record the error on the hit (SearchHit.refused with the engine's message) instead of stopping the budget
- Category: editor
- Added: 2026-11-19
