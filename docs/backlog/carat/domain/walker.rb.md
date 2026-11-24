# Backlog: carat/domain/walker.rb

## Walker depends on Motions through require order

- Where: `carat/domain/walker.rb` line 63 calls `Motions.code_class` without requiring `motions.rb`, which requires `walker.rb`, at b0dd342. Periodic quality. Queued in the backlog item batch beside the ProcessRunner entry.
- Why it matters: a hidden require cycle that works only by load order.
- Fix outline: move the class lookup into `Walker` or `Utf8` and call it there from `Motions`, `TextObjects`, and `FindMatch`.
- Category: editor
- Added: 2026-11-07

## Domain motion and text-object structure

- Where: `carat/domain/walker.rb` line 63 calls `Motions.code_class` while `motions.rb` requires `walker.rb` (a cycle held by load order), and line 11's comment omits the bracket objects; `carat/domain/text_objects.rb` line 252 builds a Walker with no require, line 86 and `carat/domain/runs.rb` name a local `cls`; `carat/domain/motions.rb` line 197 and 228 repeat an edge refusal and row clamp, line 579 a dead store; `carat/use_cases/delete_lines.rb` line 28 copies `Operate#delete`'s linewise placement (`operate.rb` line 142, also `global_command.rb` line 150); `carat/domain/operators.rb` lines 172 and 251 copy the effective shift width rule. Periodic quality at 8d8832f, queued in item 37. Raised again at ce6abdb (`walker.rb:63` and `text_objects.rb:252`, the require cycle; periodic quality), queue item `editing-counts`: move `code_class` into a module the four files require.
- Why it matters: the cycle breaks under a changed require order, and each copied rule drifts.
- Fix outline: move the character classes into one module both require; rename `cls` to `char_class`; one row-clamp helper; an `Options#shift_width` beside `tab_width`.
- Also: carat/domain/text_objects.rb, carat/domain/runs.rb, carat/domain/motions.rb, carat/use_cases/delete_lines.rb, carat/domain/operators.rb
- Category: editor
- Added: 2026-11-10

### Small core code nits from the sweep

- Location: carat/domain/walker.rb:63 (calls Motions.code_class without requiring motions.rb, a cycle hidden by load order), carat/domain/runs.rb:18 and text_objects.rb:86 (`cls`), carat/use_cases/handle_key.rb:384 and search/find_match.rb:68 (bare key codes 40, 44, 47, 63), carat/adapters/input_controller.rb:128 (both branches call handle), carat/use_cases/completion/show_completion.rb:96 (`[0]` then clear), carat/domain/range.rb:4 (stale comment), carat/domain/buffer.rb:472 (blanks public) (sprint-8 sweep, quality); queued in `editing-dedup-b`.
- Why: a hidden require cycle, a named abbreviation, magic numbers, duplication, an idiom against the codebase, a false comment, and needless public surface.
- Fix: a small CharClass module the three callers require; `char_class`; named Domain::Key constants; one handle call; `Array.new(0, 0)`; drop the sentence; move blanks below private.
- Also: carat/domain/runs.rb, carat/use_cases/handle_key.rb, carat/adapters/input_controller.rb, carat/use_cases/completion/show_completion.rb, carat/domain/range.rb, carat/domain/buffer.rb
- Category: editor
- Added: 2026-11-16

### Walker and Motions require each other through code_class

- Location: carat/domain/walker.rb:63, carat/use_cases/find_match.rb:134 (sweep, quality).
- Why: Walker calls Motions.code_class while motions.rb requires walker.rb, a hidden circular dependency; find_match.rb copies blank?.
- Fix outline: move code_class and blank? into a small character-class module both require.
- Category: editor
- Added: 2026-11-17

### Motion code keeps a require cycle, a dead store, and a cls name (sprint-14 sweep quality)

- Location: carat/domain/walker.rb:63 and carat/domain/text_objects.rb:252 (Motions.code_class used without its require, a cycle with motions.rb); carat/domain/motions.rb:599 (row = top overwritten in every branch); carat/domain/text_objects.rb:86 and carat/domain/runs.rb:90 (cls).
- Why: load-order reliance, dead code, and the abbreviation CLAUDE.md's naming rule cites as wrong.
- Fix outline: a small domain module for code_class and blank? both require; drop the store; rename to char_class. Queued in `motions-search-tidy`.
- Also: carat/domain/text_objects.rb, carat/domain/motions.rb, carat/domain/runs.rb, CLAUDE.md
- Category: editor
- Added: 2026-11-17

### Motions.code_class hides a require cycle, bare class numbers, and cls names (sprint-16 sweep quality)

- Location: carat/domain/walker.rb:63, carat/domain/text_objects.rb:86, carat/domain/runs.rb:18, carat/use_cases/search/find_match.rb:136 and :141.
- Why: Walker and TextObjects call Motions.code_class without requiring motions, which requires walker; find_match compares the class to a bare 2 and repeats class 0's blank test; locals and a parameter are named cls, which CLAUDE.md names as the bad example.
- Fix outline: move code_class into a small CharClass module that motions, text_objects, walker, and find_match require, with BLANK, PUNCTUATION, and KEYWORD constants; rename cls to char_class.
- Also: carat/domain/text_objects.rb, carat/domain/runs.rb, carat/use_cases/search/find_match.rb, CLAUDE.md
- Category: editor
- Added: 2026-11-18

### Walker#char_class calls Motions.code_class without requiring motions.rb, while motions.rb requires at carat/domain/walker.rb:62 (sprint-30 sweep quality, note 48)

- Location: carat/domain/walker.rb:62
- Why: hidden dependency cycle: Walker#char_class calls Motions.code_class without requiring motions.rb, while motions.rb requires walker.rb, and TextObjects and FindMatch reach into Motions for the same rule
- Fix: move code_class and blank? into one small domain module that walker.rb, motions.rb, text_objects.rb, and find_match.rb require
- Category: editor
- Added: 2026-11-23

### the class comment says it is used only while at carat/domain/walker.rb:12 (sprint-30 sweep quality, note 52)

- Location: carat/domain/walker.rb:12
- Why: doc drift: the class comment says it is used only while a word motion runs, but TextObjects.find_opener and find_closer walk with it too
- Fix: say it serves the word motions and the bracket text objects
- Category: editor
- Added: 2026-11-23

### Walker calls Motions.code_class, but motions.rb requires walker.rb and walker.rb does at carat/domain/walker.rb:63 (sprint-32 sweep quality, note 59)
- Location: carat/domain/walker.rb:63
- Why: Walker calls Motions.code_class, but motions.rb requires walker.rb and walker.rb does not require motions, so the two files depend on each other and it works only by load order; text_objects.rb:255 also uses Walker without requiring walker.rb
- Fix: move code_class (and blank?) into a small domain module that walker, motions, text_objects, find_match, and command_line_text require
- Category: quality
