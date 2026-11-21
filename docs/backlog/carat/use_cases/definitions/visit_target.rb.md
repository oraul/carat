# Backlog: carat/use_cases/definitions/visit_target.rb

## gd inside a focused float works on the float

- Where: `carat/use_cases/definitions/visit_target.rb` lines 70 and 83 at fafe59c, `jump` and `place`, which use `state.window`, the focused float when one is entered, while `RequestDefinition` asks at `state.tab.layout_window`. Quality advisory in `definitions`; the Ctrl-O and Ctrl-I part was fixed in the change, `WalkJumps` doing nothing while a float has the focus.
- Why it matters: `gd` inside an entered hover float pushes the float's scratch buffer onto the jump list and loads the target into the float, since `BufferList#load` shows into `tabs.window`.
- Fix outline: refuse `definition.*` while a float is focused, as `WalkJumps` does, or close the focused float first and work on the layout window, with a row pressing `gd` in an entered hover float.
- Category: editor
- Added: 2026-11-10

## A symlinked working directory opens the edited file read-only

- Where: `carat/use_cases/definitions/visit_target.rb` line 166 at fafe59c, `absolute`, and `inside?` at line 160, which compare against the working directory as given. Quality advisory in `definitions`.
- Why it matters: with a symlinked working directory and a server answering resolved paths, a target in the edited file compares unequal and fails `inside?`, so `gd` opens a read-only duplicate view instead of jumping.
- Fix outline: also compare against the resolved working directory, with a row for a symlinked working directory.
- Category: editor
- Added: 2026-11-10

## The definition column walk copies the gateway's UTF-16 walk

- Where: `carat/use_cases/definitions/visit_target.rb` line 196, `column_of`, against `JsonRpcLanguageGateway#utf16_offset` and `#utf16_length` (lines 1111 and 1157); the cursor-float widest-row loop in `show_completion_docs.rb` line 100 and `show_key_hints.rb` line 128 beside the entry "Definition float and row clamp copy other use cases". Periodic quality at 8d8832f, queued in `definitions-tidy`.
- Why it matters: two UTF-16 walks drift apart on multibyte text; the float loop has four copies.
- Fix outline: one domain UTF-16 helper used by both, with multibyte rows; one owner for the float sizing.
- Category: editor
- Added: 2026-11-10

## listed_for recomputes the target's absolute path per buffer

- Where: `listed_for` in `carat/use_cases/definitions/visit_target.rb` line 142 at 75fa4fd, which calls `absolute(path)`, a join and a normalize, on every iteration of its loop over the listed buffers. Quality advisory in `periodic-blockers-a`.
- Why it matters: the target path does not change inside the loop, so each listed buffer costs one more join and normalize, and the allocations grow with the buffer list on every `gd` and peek.
- Fix outline: compute the target's absolute path once before the loop and compare each buffer's path against it.
- Category: editor
- Added: 2026-11-10

## Two class comments of the definitions change are wrapped unevenly

- Where: `carat/use_cases/definitions/visit_target.rb` line 28 (line 29 stops at 45 columns) and `carat/use_cases/buffers/list_buffers.rb` line 16 (runs to 88 columns against the 72 to 75 of its block). Quality advisory in `gd-ghost-tab`.
- Why it matters: the ragged block reads as an unfinished edit and breaks the file's wrap width, as in the comments entry above.
- Fix outline: rewrap both class comments evenly at the width of their block.
- Also: carat/use_cases/buffers/list_buffers.rb
- Category: editor
- Added: 2026-11-10

## VisitTarget keeps a dead parameter and a copied read

- Where: `carat/use_cases/definitions/visit_target.rb:93` (`view` never reads `state`) and `:101` against `:116` (probe, refusal, read, and E484 twice).
- Why it matters: dead code and one rule kept in two places.
- Fix outline: drop the parameter; one private helper reading a target within a limit. Queue item `definitions-tidy`.
- Category: editor
- Added: 2026-11-10

## The gd peek and finder preview show code unhighlighted

- Where: `carat/use_cases/definitions/visit_target.rb:132`; `carat/use_cases/syntax/highlight_view.rb:43`; `carat/adapters/frame_presenter.rb:647`. Periodic quality.
- Why it matters: the peek's filetype is set but nothing reads it, so the peek is plain.
- Fix outline: highlight floats' visible rows and paint their tokens, with a row in `test/adapters_definitions.rb`, or drop the assignment. Queue item `definitions-tidy`.
- Also: carat/use_cases/syntax/highlight_view.rb, carat/adapters/frame_presenter.rb, test/adapters_definitions.rb
- Category: editor
- Added: 2026-11-10

## VisitTarget's comment omits jumptab and scans the list three times

- Where: `carat/use_cases/definitions/visit_target.rb:27` and `:83`. Periodic quality advisory.
- Why it matters: the class comment never mentions `option.jumptab replace`; `listed_for` runs up to three times a jump (see the existing `listed_for` entry).
- Fix outline: one comment sentence; pass the held buffer into `view` and `open_path`. Queue item `definitions-tidy`.
- Category: editor
- Added: 2026-11-10

## VisitTarget pushes a cross-file jump that enter already recorded

- Where: `carat/use_cases/definitions/visit_target.rb:87`, against `BufferList#enter` reached through `OpenFile` or `view`. Quality advisory of `jump-list`.
- Why it matters: for a jump to another file `enter` already pushed the same entry, so this push only re-appends it, and after a reused startup buffer it records an entry under the id the target took.
- Fix outline: push explicitly only in the same-file case and leave cross-file jumps to `enter`, with a row asserting one entry per cross-file `gd`. Queue item `definitions-tidy`.
- Category: editor
- Added: 2026-11-10
