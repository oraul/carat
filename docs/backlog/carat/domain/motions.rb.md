# Backlog: carat/domain/motions.rb

## Motions take the whole editor state and write the last find

- Where: `Carat::Domain::Motions` in `carat/domain/motions.rb`, which receives `EditorState` in every motion and records f, F, t, and T in the `LastFind` record `for_command` receives (since `state-and-ports`), and `TextObjects`, which receives the state too.
- Why it matters: a motion is meant to be a pure function of the text and the cursor (section 4 of `docs/architecture.md`), but with the whole state it can reach windows, registers, and modes, and the side effect on `last_find` makes it impossible to evaluate a motion speculatively, for a preview, a plugin, or a language service, without changing what `;` and `,` repeat.
- Fix outline: pass the buffer, the cursor, and the viewport (top row and height for `H`, `M`, `L`) as values, return the find to record alongside the `Motion`, and have `Move` and `Operate` store it in the `LastFind` record they already receive.
- Also: docs/architecture.md
- Category: editor
- Added: 2026-10-31

## Sentence motions rescan the whole buffer on every use

- Where: `Carat::Domain::Motions.sentence_starts` in `carat/domain/motions.rb` (line 416 at 7711421), called by `(` and `)` and by the `is` and `as` text objects in `carat/domain/text_objects.rb` (line 150 at 7711421). Raised again at ce6abdb (`motions.rb:398`, `sentence_starts`, on every `(`, `)`, `is`, or `as`; periodic quality), queue item `editing-counts`: scan from the paragraph before the cursor to the one after, or cache the starts by the buffer's change count.
- Why it matters: every use builds the list of sentence starts for the whole buffer, so one `)` takes about 96 ms on 100,000 lines, and a count or a repeated key multiplies it.
- Fix outline: scan outward from the cursor, backward to the start of the current sentence and forward to the start of the next, stopping at a paragraph boundary, and reuse that walker for the text objects.
- Also: carat/domain/text_objects.rb
- Category: editor
- Added: 2026-10-31

## Some per-command character loops still slice one-character strings

- Where: the find motions `f`, `F`, `t`, and `T` and the sentence scan in `carat/domain/motions.rb` (`line[col, 1]`), `Block#span` in `carat/domain/block.rb`, `Selection.cells` in `carat/domain/selection.rb`, the quote objects and the trailing blanks of `as` in `carat/domain/text_objects.rb`, the join and the indent helpers in `carat/domain/operators.rb`, the indent loops of `carat/use_cases/actions/insert_mode_handler.rb` and `carat/use_cases/move.rb`, the blank test in `carat/use_cases/operate.rb`, and the name scan of `carat/domain/ex_grammar.rb`.
- Why it matters: Spinel resolves `line[i, 1]` on a line that is not ASCII from the start of the line, so these loops are quadratic on a long UTF-8 line; `render-core` moved the paint path, `DisplayWidth.column` and `col_at`, the word motions' `Walker`, the word runs of the text objects, `first_nonblank`, and `indent_of` to code points or bytes, but these run once per command, not per frame, and were left as they were.
- Fix outline: walk them with `Utf8.size_at` and `code_at`, or decode the line once with `Utf8.codes`, and compare code points instead of one-character strings; blanks and ASCII punctuation can compare bytes directly, as `Buffer#blanks` does.
- Also: carat/domain/block.rb, carat/domain/selection.rb, carat/domain/text_objects.rb, carat/domain/operators.rb, carat/use_cases/actions/insert_mode_handler.rb, carat/use_cases/move.rb, carat/use_cases/operate.rb, carat/domain/ex_grammar.rb
- Category: editor
- Added: 2026-11-01

## Motions repeats its row clamp and paragraph walk

- Where: `carat/domain/motions.rb` line 246 (`line_down` repeats `vertical`'s checks at lines 215 to 222, `to_row` clamps again), lines 540 and 562 (`paragraph_forward` and `paragraph_backward` share one loop), at 7711421. Periodic quality. Queue item `editing-counts`. Raised again at ce6abdb (`motions.rb:228`, `line_down`, and 544, the paragraph loops; periodic quality): a `step_row` helper.
- Why it matters: three clamps and two walks to keep in step.
- Fix outline: one private row clamp and one paragraph walker taking the step.
- Category: editor
- Added: 2026-11-09

## Sentence motions rescan the starts linearly

- Where: `carat/domain/motions.rb:468` and `:500`. Periodic quality. Raised again at be4b63a (owner `editing-counts`).
- Why it matters: they duplicate `SentenceStarts#index_at` and rebuild a Position.
- Fix outline: `next_after` and `last_before` on `SentenceStarts`. Queue item `editing-counts`.
- Category: editor
- Added: 2026-11-10

## Vertical motions clamp the row twice

- Where: `carat/domain/motions.rb:197`, `:210`, `:228`. Periodic quality.
- Why it matters: the same edge check and clamp in two methods and again in `to_row`.
- Fix outline: one clamped-row helper. Queue item `editing-counts`.
- Category: editor
- Added: 2026-11-10

## The % motion repeats the text objects' bracket walk (sprint-2 sweep)

- Where: `match_pair` and `pair_kind` in `carat/domain/motions.rb:630` against `find_opener` and `find_closer` in `carat/domain/text_objects.rb:251` and `:268`. Periodic quality at 8b9bf6a, raised twice.
- Why it matters: two nested bracket walks in two forms (bytes against Walker) can drift apart.
- Fix outline: one bracket matcher in Motions, which TextObjects already requires, used by `%` and the pair objects, with the existing rows held.
- Also: carat/domain/text_objects.rb
- Category: editor
- Added: 2026-11-14

### Sentence motions loop once per count past the last sentence

- Location: carat/domain/motions.rb:488 and :520 (sprint-4 sweep, quality blocking).
- Why: sentence_forward and sentence_backward rescan every start once per remaining count, O(count x starts), so `999999999)` freezes the editor where word motions stop at the buffer edge.
- Fix: stop when no start is found and resume from the last one; a large-count row in test/editor_motions.rb.
- Also: test/editor_motions.rb
- Category: editor
- Added: 2026-11-14

### Paragraph motions never answer nil
- Location: carat/domain/motions.rb:542
- Why: paragraph_forward and paragraph_backward return a position even when the cursor already stands there, against the module contract sentence_forward keeps. Folded into core-correctness-b.
- Fix: return nil when the target equals the cursor.
- Category: editor
- Added: 2026-11-17
