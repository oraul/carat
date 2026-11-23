# Backlog: carat/use_cases/search/find_match.rb

## FindMatch re-implements the domain's character classes

- Where: `FindMatch#keyword?` and `#blank?` in `carat/use_cases/search/find_match.rb` (line 129), `keyword?` through the bare class number in `Motions.code_class(code, false) == 2`. Periodic quality at 0b17324. Raised again at ce6abdb (`find_match.rb:134`, `blank?`; periodic quality), queue item `editing-counts`.
- Why it matters: the word under the cursor for `*` and `#` is judged by a copy of the classes `Domain::Motions` owns, keyed on an unnamed number, so a change to the classes leaves the search motion behind.
- Fix outline: a code-point predicate in `Domain::Motions` (or a named class constant) called from `FindMatch` and the runs scan. Queued in `search-structure`.
- Category: editor
- Added: 2026-11-04

## Small code findings of the 7711421 periodic review

- Where: `carat/use_cases/search/find_match.rb` line 163 and `substitute_lines.rb` line 143 (E486 as a literal, not a `Search` constant); `carat/use_cases/actions/motion_handler.rb` line 52 (a comment missing words) and `carat/domain/find.rb` line 3 (describes `LastFind`'s role); `carat/domain/vim_pattern.rb` line 23 (three escapes listed twice). Queue item `search-tidy`.
- Why it matters: a message spelled twice and three wrong comments.
- Fix outline: `Search::NOT_FOUND` used by both; reword the two comments; drop the second mention.
- Also: carat/use_cases/actions/motion_handler.rb, carat/domain/find.rb, carat/domain/vim_pattern.rb
- Category: editor
- Added: 2026-11-09

## Search copies its prompt split and its E486 message

- Where: `carat/use_cases/search/find_match.rb` line 68 against `preview_search.rb` line 106 (the `pattern_end` split on bytes 47 or 63), and line 163 against `substitute_lines.rb` line 143 (the E486 literal). Periodic quality at 8d8832f, queued in `editing-counts`. Raised again at ce6abdb (`find_match.rb:68`, code points 47 and 63; periodic quality).
- Why it matters: a fix to one split or message misses its copy.
- Fix outline: one domain helper for each, used by both callers.
- Category: editor
- Added: 2026-11-10

## The E486 message is built inline

- Where: `carat/use_cases/search/find_match.rb:163`. Periodic quality.
- Why it matters: every other search message is a `Domain::Search` constant.
- Fix outline: a not-found prefix constant. Queue item `search-tidy`.
- Category: editor
- Added: 2026-11-10

## Search and pattern code keeps magic numbers and a literal message

- Where: `carat/use_cases/search/find_match.rb:68`, `:163`; `preview_search.rb:37`; `carat/domain/vim_pattern.rb:641`; `carat/domain/walker.rb:63`. Periodic quality.
- Why it matters: the delimiter is `47 : 63` twice, E486 is the only literal search message, `collection_end`'s comment names the wrong byte, and `Walker` calls `Motions.code_class` without requiring it.
- Fix outline: a delimiter method, `Search::NOT_FOUND`, a reworded comment, one shared class-table module. Queue item `search-tidy`.
- Also: carat/domain/vim_pattern.rb, carat/domain/walker.rb
- Category: editor
- Added: 2026-11-10

### The search delimiter bytes are written twice
- Location: carat/use_cases/search/find_match.rb:68; carat/use_cases/search/preview_search.rb:37
- Why: 47 and 63 for / and ? repeated. Folded into editing-dedup-a.
- Fix: one domain helper used by both.
- Also: carat/use_cases/search/preview_search.rb
- Category: editor
- Added: 2026-11-17

### Character classes are bare numbers
- Location: carat/use_cases/search/find_match.rb:130; Motions.code_class, Walker.char_class, TextObjects.runs
- Why: 0, 1, 2 compared by hand and blank? re-derives class 0. Folded into editing-dedup-a.
- Fix: named constants BLANK, OTHER, KEYWORD in Motions, keyword? and blank? built on them.
- Category: editor
- Added: 2026-11-17

### Search code copies a class helper and a register loop (sprint-14 sweep quality)

- Location: carat/use_cases/search/find_match.rb:177; carat/use_cases/actions/motion_handler.rb:33, search_handler.rb:36, text_object_handler.rb:34 (the loop in fifteen handlers).
- Why: blank? re-implements Motions.code_class == 0; one names-descriptions loop is repeated.
- Fix outline: reuse the domain helper; an ActionTable method registering a list. Queued in `motions-search-tidy`.
- Also: carat/use_cases/actions/motion_handler.rb
- Category: editor
- Added: 2026-11-17

### Four sites compile a search against the last substitute by hand (sprint-15 review quality)

- Location: carat/use_cases/search/find_match.rb:83, carat/use_cases/search/preview_search.rb:46, global_command.rb:65, last_search.rb:70 (LastSearch#recompile); SetCommandHandler holds a LastSubstitute only to pass it through.
- Why: VimPattern.compile_search(source, ignorecase, smartcase, previous, previous_kept) is spelled in 4 places, so a change to how ~ reads the last substitute must be made in each.
- Fix outline: one domain helper taking (source, options, last_substitute), or LastSearch keeping the LastSubstitute it recompiles against.
- Also: carat/use_cases/search/preview_search.rb
- Category: editor
- Added: 2026-11-17

### carat/use_cases/search/find_match.rb:140: duplication: blank? re-states the blank class Motions.code_class answers as (sprint-22 sweep quality)

- Location: `carat/use_cases/search/find_match.rb:140`
- Why: duplication: blank? re-states the blank class Motions.code_class answers as 0 (and Motions.blank? for strings)
- Fix: Motions.code_class(code, false) == 0, keyword? beside it already reads code_class
- Category: editor
- Added: 2026-11-20

### the private blank? and keyword? restate Motions.code_class (class 0 at carat/use_cases/search/find_match.rb:140 (sprint-30 sweep quality, note 49)

- Location: carat/use_cases/search/find_match.rb:140
- Why: duplication: the private blank? and keyword? restate Motions.code_class (class 0 and class 2)
- Fix: compare Motions.code_class(code, false) directly, or use the shared module of the walker.rb:62 note
- Category: editor
- Added: 2026-11-23

### the E486 not-found message is built inline while every at carat/use_cases/search/find_match.rb:169 (sprint-30 sweep quality, note 53)

- Location: carat/use_cases/search/find_match.rb:169
- Why: consistency: the E486 not-found message is built inline while every other search message is a Search constant
- Fix: add Search::NOT_FOUND and use it
- Category: editor
- Added: 2026-11-23
