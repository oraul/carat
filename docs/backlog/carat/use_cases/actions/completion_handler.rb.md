# Backlog: carat/use_cases/actions/completion_handler.rb

## Completion code style advisories

- Where: `CompletionHandler.register` in `carat/use_cases/actions/completion_handler.rb` (line 45 at 334d899) repeats the five-keyword constructor five times; the `completion` keyword and reader of `HandleKey` in `carat/use_cases/handle_key.rb` (line 60) hold a `Domain::CompletionMenu` that the assembly and every use case call `completion_menu` or `menu`; `row_offset` in `carat/use_cases/completion/show_completion.rb` (line 145) subtracts an unexplained 2 from `screen_rows`; the `paint_float_row` comment in `carat/adapters/frame_presenter.rb` (line 466) still says the text is drawn in NormalFloat though a menu's rows are Pmenu and PmenuSel; the PageDown row of `test/editor_completion.rb` (line 81) asserts only the row and the closed popup. Quality advisories in `completion`.
- Why it matters: the register and reader names differ from the style of their neighbours, the 2 and the comment mislead a reader of the layout and the paint path, and the PageDown row would pass with an empty word at column 0, so it does not show the not-typed branch ran.
- Fix outline: loop over parallel names, variants, and descriptions arrays as `BufferHandler.register` does; rename the keyword and reader to `completion_menu`; name the reserved rows in a private constant or read the free rows from the layout area `ArrangeView` uses; say "its text in float_group's group"; assert the cursor column 2 and `h.completions.asked == 1` in the PageDown row as the cursor-binding row does.
- Also: carat/use_cases/handle_key.rb, carat/use_cases/completion/show_completion.rb, carat/adapters/frame_presenter.rb, test/editor_completion.rb
- Category: ide
- Added: 2026-11-07

## Every completion handler variant holds CompleteWord

- Where: `CompletionHandler` in `carat/use_cases/actions/completion_handler.rb` line 28 at eb0b1ae, whose every popup variant now takes `complete_word` though only the two `keymap.insert` variants (`completion.keyword_next`, `completion.keyword_previous`) use it. Quality advisory in `word-completion`.
- Why it matters: the popup handlers carry a collaborator they never call, widening the handler the backlog already records as repeating its constructor.
- Fix outline: a separate `KeywordCompletionHandler` holding only `CompleteWord` and registering the two keyword actions, wired in `EditorAssembly` with its `docs/actions.md` rows unchanged. Queued in `completion-tidy`.
- Also: docs/actions.md
- Category: ide
- Added: 2026-11-10
