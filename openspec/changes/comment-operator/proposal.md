# Proposal

## Why

Carat has no comment operator, so `gc` falls through: `g` alone is a keymap prefix, `gc` is no binding, both keys are dropped, and the next `c` starts a change, which deletes text (`3G gcc 8G` wipes lines 3 to 8). A Neovim user types `gc` daily; today it loses work. The user decided on 2026-11-21 (the design council, decision 1: "fix gc now") to deliver Neovim 0.10's built-in commenting first in the feature lane. It lies outside the roadmap of `docs/architecture.md` section 12 as a user request that closes a data-losing gap in core modal editing.

## What Changes

- A new pending operator `gc` (`operator.comment`): `gc{motion}` toggles the comment of the lines a motion or text object covers, with counts (`3gcj`, `gcip`); `gcc` toggles [count] lines, the doubled form being the operator's last key repeated.
- Visual `gc` toggles the comment of the selected lines in visual, visual_line, and visual_block.
- A text object `gc` (`textobject.comment`) in operator_pending selects the adjacent commented lines around the cursor (`dgc`, `ygc`), and nothing when the cursor line is not commented.
- The toggle rule of Neovim: when every non-blank line of the range is commented, every one is uncommented (the marker and one following space removed); otherwise every non-blank line is commented, the marker and one space placed at the smallest indent of the range. Blank lines are left untouched.
- The marker comes from the buffer's filetype through one table (`#` for ruby); an unknown filetype uses `#`.
- The toggle is one undo step and `.` repeats it.
- Keymap lines in `config/default.caratrc` for normal, operator_pending, visual, visual_line, and visual_block, mirrored in `carat/domain/default_config.rb`.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `operators`: ADDED requirements "Comment operator", "Comment toggle rule", "Comment marker by filetype", "Repeating and undoing a comment toggle", and "Comment operator in the visual modes".
- `text-objects`: ADDED requirement "Comment object".

## Out of scope

- No `commentstring` option: the marker table is fixed; an option to set it per buffer is a later change.
- Markers with a right part (`/* %s */`) are not needed by any filetype carat detects today; the table holds a left marker only.
- The doubled last-key form is enabled for `gc` only; `g~~`, `guu`, and `gUU` stay as they are.
- The Sprint 25 exception line and the `one-accent` and `glyph-audit` placements in `docs/queue-feature.md` come with the planner's queue through `plan-apply` at the package step, so this change does not write them by hand. No file of the backlog lane and no `tools/rules.sh` edit.
- Assumption: after a toggle the cursor goes to the first non-blank of the range's first line, as after `>`.
- Assumption: uncommenting a line holding only the marker (and blanks) leaves an empty line, so no trailing blanks remain.

## Impact

- README.md: changed, the editing feature list names the comment operator.
- docs/architecture.md: changed, the operators paragraph of section 5 names `gc` and the `Comments` domain module.
- docs/codebase-map.md: area 7 names `carat/domain/comments.rb`, `carat/use_cases/visual/comment_selection.rb`, and `test/editor_comments.rb`.
- docs/compatibility.md: rows for `gc`, `gcc`, visual `gc`, and the `gc` text object, the missing `commentstring` option listed as a difference.
- docs/actions.md: rows for `operator.comment` and `textobject.comment`.
- CLAUDE.md: unchanged, no process change.
- Performance: no hot path changes; the toggle reads the range's lines once and writes them with one `set_lines`.
