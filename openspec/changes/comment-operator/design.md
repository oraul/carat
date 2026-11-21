# Design

## Context

`g` is a keymap prefix in normal mode and `gc` had no binding, so `HandleKey` dropped both keys and the next `c` began `operator.change`. The operators live in `Operate` (normal and operator_pending) and in one selection use case per operation (visual), all registered by `OperatorHandler.register`. Text objects are `Domain::TextObjects`, registered with the kind `:text_object` from its `NAMES`.

## Decisions

- One domain module, `Carat::Domain::Comments` (`carat/domain/comments.rb`), holds the marker table `MARKERS` (filetype to marker, `"ruby" => "#"`), the default `"#"`, `marker_for(filetype)`, `commented?(line, marker)`, `toggle(buffer, from, to, marker)`, and `block(buffer, row, marker)`. A later filetype is one row of `MARKERS`. Shared by `Operate`, `CommentSelection`, and `TextObjects`, as `Operators` is shared.
- `toggle` builds the new lines of the range and writes them with one `Buffer#set_lines` when any line changed, so the dispatcher's one transaction per command makes it one undo step and an all-blank range changes nothing (the modified flag stays). Indent is the shortest leading-blank prefix of the non-blank lines, by characters, as Neovim compares it by bytes; the leading blanks are ASCII, so the two agree.
- `OperatorKind::COMMENT = "operator.comment"`, registered by `OperatorHandler.register` with the variant `:comment`; `Operate#call` toggles the whole rows of the range. Its visual branch calls the new `CommentSelection` use case (`carat/use_cases/visual/comment_selection.rb`), built in `EditorAssembly` beside `ShiftSelection`; it toggles `selection.top` to `selection.bottom` for every visual kind, blockwise included, as Neovim's `x_gc` works on lines.
- `gcc`: a doubled operator is its action typed again (`dd`); `gc` typed again in operator_pending is the text object, so `gcc` needs the operator's last key repeated. `CommandGrammar` keeps the keys of the pending operator (`operator_keys`) and reads a one-key action whose key equals the last of them as the doubled form, for the operators in `LAST_KEY_DOUBLED`, which holds only `OperatorKind::COMMENT`. Keeping the list to `gc` leaves `g~~`, `guu`, and `gUU` unchanged (out of scope). This follows the user's binding: if `gc` is rebound to other keys, the last of those keys doubles it.
- `textobject.comment` joins `TextObjects::NAMES`; it returns a linewise range of the adjacent commented rows, or nil off a comment, so the operator does nothing.
- Cursor after a toggle: first non-blank of the first row, as after `>` and visual `>`.
- `.` needs nothing new: `OperatorHandler` is `repeat: true`, so the dispatcher records the command and replays it through `Operate`, and a visual `gc` replays over the measured selection as visual `>` does.

## Risks

- A line whose marker is followed directly by text (`#b`) uncomments to `b`, and a line that only starts with `#` for another reason (a Ruby string interpolation never starts a line) counts as commented, as in Neovim.
