# Design

## Context

`cmdline` is one String every prompt shares; the frame put the cursor after it. Terminals send a Ctrl or Shift arrow as a CSI sequence with a modifier, which the decoder dropped.

## Decisions

- A cursor member, not a second text: `cmdline_position` is a character index (`String#[]` units, as `EraseCommandLine` already counted), so the use cases, which never see a width, stay in characters and only `FramePresenter` converts to cells (`DisplayWidth.text_width` of the text before the cursor).
- The member holds the characters after the cursor (`cmdline_after`, 0 at the end), so a text set without `replace_cmdline` (a test, a plugin path) has its cursor at the end, and an insert or a delete before the cursor leaves the member as it is; `replace_cmdline(text)` is the writer every opener uses, and the reader clamps a stale value.
- Two use cases with a motion or unit argument (`call(state, :word_left)`, `call(state, :word)`), as `RecallHistory` takes `older`; one handler registers the nine names with one variant each.
- New keys over a modifier-aware keymap: the four keys are codes like `<C-PageUp>`. To keep every mode as it was, where the decoder used to give Left or Right, `HandleKey#lookup` retries an unbound single modified arrow as the plain arrow; the cmdline binds them first.
- Word rules from Neovim: `<S-Left>`/`<S-Right>` by blank-separated word; `<C-w>` skips blanks and then one run of word characters (letters, digits, underscore, any non-ASCII) or one run of other non-blank characters; `<Del>` at the end is `<BS>`.
- Completion is not here: the cursor is the part it needs first, and a completion popup is a float painter change of its own.

## Risks

- A site that sets `cmdline` directly after a cursor move keeps the old count of characters after the cursor; `test/editor_cmdline_edit.rb` opens each prompt kind and checks the cursor is at the end.
