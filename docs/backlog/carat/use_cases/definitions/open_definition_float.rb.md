# Backlog: carat/use_cases/definitions/open_definition_float.rb

## Definition float and row clamp copy other use cases

- Where: `carat/use_cases/definitions/open_definition_float.rb` line 30 at fafe59c duplicates `ShowHover#open` (`carat/use_cases/docs/show_hover.rb` line 74): the below-or-above placement, height, width, and `FloatSpec`; `carat/use_cases/definitions/walk_jumps.rb` lines 51 to 53 repeat the row clamp of `VisitTarget#place` and `#clamp` (`visit_target.rb` lines 180 and 187). Quality advisories in `definitions`.
- Why it matters: section 5 of `docs/architecture.md` moves logic several use cases share into the domain or one use case; two copies of the cursor-float placement drift apart.
- Fix outline: have `ShowHover` open its float through the one use case (named for what it does, such as `OpenCursorFloat`) or move the placement into a domain helper both call; add `EditorState#clamp_row` beside `clamp_col` and call it from `WalkJumps` and `VisitTarget`.
- Also: carat/use_cases/docs/show_hover.rb, carat/use_cases/definitions/walk_jumps.rb, docs/architecture.md
- Category: editor
- Added: 2026-11-10
