# Backlog: carat/use_cases/docs/show_hover.rb

## The documentation floats copy the widest-row loop

- Where: `carat/use_cases/docs/show_hover.rb` line 84 at 78078ad, a copy of `carat/use_cases/completion/show_completion_docs.rb` line 98 and of `carat/domain/operators.rb` line 139. Quality advisory in `quick-docs`.
- Why it matters: the float width is computed three ways, so a fix for wide or combining characters lands in one float only.
- Fix outline: a `DisplayWidth.widest(rows)` helper used by both floats and the operator, with the hover and completion-docs rows unchanged.
- Also: carat/use_cases/completion/show_completion_docs.rb, carat/domain/operators.rb
- Category: ide
- Added: 2026-11-07

## The hover-docs spec and the code place the float differently

- Where: the placement in `carat/use_cases/docs/show_hover.rb` line 76 at 78078ad, and the placement requirement of `openspec/specs/hover-docs/spec.md`. Quality advisory in `quick-docs`.
- Why it matters: the code puts the float above when below lacks the rows and above has more, while the spec says above only when only above has the room; the spec no longer tells a reader what the editor does.
- Fix outline: align the spec wording with the code through a proposal, with a row for each placement.
- Also: openspec/specs/hover-docs/spec.md
- Category: ide
- Added: 2026-11-07

## The hover placement counts rows with bare numbers

- Where: `below = state.screen_rows - 4 - screen_row` and `above = screen_row - 2` in `ShowHover#open`, `carat/use_cases/docs/show_hover.rb` line 72 at 41297d6. Quality advisory in `quick-docs`.
- Why it matters: the 4 and the 2 are the float's two border rows and the status and command lines, which a reader has to reconstruct, and a change to the bars or the border would miss them.
- Fix outline: name them (a `BORDER` of 2 and the rows the bars take) in private constants, or say so in a comment.
- Category: ide
- Added: 2026-11-07

## The hover float above the cursor and a refused pin have no test

- Where: `ShowHover#open`'s `up` branch in `carat/use_cases/docs/show_hover.rb` and `PinHover` in `carat/use_cases/docs/pin_hover.rb`; the tests are `test/adapters_hover.rb` line 176 at 41297d6. Quality advisory in `quick-docs`; the crash with a hover in flight is the entry Hover paths in the spec or the code have no test.
- Why it matters: the float placed above the cursor and a split refused for lack of room, which must keep the float, can regress without a test failing.
- Fix outline: add a case with the cursor on the last screen rows and one pressing the pin key in a window too small to split.
- Also: carat/use_cases/docs/pin_hover.rb, test/adapters_hover.rb
- Category: ide
- Added: 2026-11-07

### ShowHover repeats the definition float's placement

- Location: carat/use_cases/docs/show_hover.rb:74, carat/use_cases/definitions/open_definition_float.rb:29 (sprint-8 sweep, quality, found twice); queued in `hover-tidy`.
- Why: the below-or-above room, height clamp, width loop, and bordered FloatSpec are copied line for line.
- Fix: one cursor-float use case taking the built buffer, both callers using it.
- Also: carat/use_cases/definitions/open_definition_float.rb
- Category: ide
- Added: 2026-11-16

### ShowHover repeats the definition float's placement (sprint-16 sweep quality)

- Location: carat/use_cases/docs/show_hover.rb:75, OpenDefinitionFloat#call.
- Why: the below, above, height clamp, and widest-row placement is copied almost line for line.
- Fix outline: open through OpenDefinitionFloat or a shared placement helper with a row cap. Pool item `lsp-tidy`.
- Category: ide
- Added: 2026-11-18

### Duplication (sprint-20 sweep quality, show_hover.rb:76)

- Location: `carat/use_cases/docs/show_hover.rb:76`
- Why: duplication: the cursor-float placement (screen row, room below and above, up when below lacks rows, height clamp, FloatSpec row -(height+2) or 1) is copied line for line in carat/use_cases/definitions/open_definition_float.rb:32
- Fix: let ShowHover open its float through the one placement (OpenDefinitionFloat renamed OpenCursorFloat, or a Domain::FloatWindow helper returning the spec) and drop the copy
- Also: carat/use_cases/definitions/open_definition_float.rb
- Category: ide
- Added: 2026-11-19
