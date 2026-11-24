# Backlog: carat/domain/buffer.rb

## Diagnostic marks moving on undo, redo, and reload have no test

- Where: `shift_signs` in `revert` and `reapply` and the reload path of `carat/domain/buffer.rb` (line 623 at 38d8c47); `test/domain_buffer.rb` covers only `set_lines`. Quality advisory at `diagnostics-display`.
- Why it matters: the marks now move on `u`, `<C-r>`, and reload, but a regression there would draw a sign on the wrong row without a failing test.
- Fix outline: add rows for `u` and `<C-r>` over a line inserted above a marked row and one for reload.
- Also: test/domain_buffer.rb
- Category: editor
- Added: 2026-11-07

## Buffer requires diagnostic twice

- Where: `require_relative "diagnostic"` in `carat/domain/buffer.rb` (line 15 at 38d8c47). Quality advisory at `diagnostics-display`.
- Why it matters: `diagnostic_list.rb` already requires it, and the line sits apart from the other new require.
- Fix outline: remove the line.
- Category: editor
- Added: 2026-11-07

## Buffer#blanks is public with callers only in its file

- Where: `carat/domain/buffer.rb` line 438 at 847851d. Periodic quality. Queue item: backlog items, needless public methods.
- Why it matters: a needless public method widens `Buffer`'s surface.
- Fix outline: move it below `private`.
- Category: editor
- Added: 2026-11-09

### carat/domain/buffer.rb:58 styles comment names only the documentation buffer

Docs currency: the styles comment (and FramePresenter#paint_float_row's at carat/adapters/frame_presenter.rb:628) still say styles belong to a documentation buffer, while the palette's menu buffer now carries them. Fix: say a styled float's rows (documentation or palette menu).
- Also: carat/adapters/frame_presenter.rb
- Category: editor
- Added: 2026-11-14

### revert_to leaves restored rows unmarked for :g

- Location: `carat/domain/buffer.rb:656` (`revert_to`), `GlobalMarks#shift`, and the global spec's revert requirement.
- Why: `revert_to` moves the global marks back, but rows the reverted edit had deleted come back unmarked because `GlobalMarks#shift` inserts unmarked rows, so the comment's "return to how they were" and the global spec's requirement overclaim and `:g` skips those lines; quality advisory from core-correctness.
- Fix: keep the removed rows' flags with the change record and restore them on revert, or narrow the comment and the requirement to inserted rows, with a test row that reverts a deletion of a marked line.
- Category: editor
- Added: 2026-11-15

### Buffer#line reads the last line for a negative row

- Location: carat/domain/buffer.rb:406 (sprint-8 sweep, quality); queued in `core-correctness-b`.
- Why: the method says it gives an empty string outside the buffer but `lines[-1]` answers a negative row; every caller guards today.
- Fix: return "" when row < 0, with a domain_buffer test row.
- Category: editor
- Added: 2026-11-16

### Deleting an empty charwise range marks the buffer modified
- Location: carat/domain/buffer.rb:504 (Buffer#delete)
- Why: d0 at column 0, d^ on the first non-blank, or c0 at column 0 splices an identical line, so the buffer shows modified, :q refuses with E37, a no-op undo state is pushed, and plugins and the language server get a change notice; Neovim changes nothing. Folded into core-correctness-b.
- Fix: return early for an empty one-row range (or skip it in Operate), with a d0-at-column-0 row asserting modified? stays false.
- Category: editor
- Added: 2026-11-17

### revert_to repeats splice's row shifting
- Location: carat/domain/buffer.rb:653 and 687-689
- Why: a new per-line layer must be added in two places. Folded into editing-dedup-a.
- Fix: a private shift_rows(row, removed, inserted) used by both.
- Category: editor
- Added: 2026-11-17

### Marked fold copies outlive a committed plugin edit
- Location: carat/domain/buffer.rb:640
- Why: the fold copies taken by transaction_mark are cleared only by revert_to, so after a successful plugin edit they stay, holding a closed window's Folds alive, and a later revert_to without a fresh mark, for example with transaction_size, restores stale folds, contrary to the risk note of the vim-folds-b design.
- Fix: clear marked_folds and marked_fold_copies in commit_transaction and on revert_to's early return, and add a test of revert_to after a committed marked edit.
- Category: editor
- Added: 2026-11-18

### mark_folds copies every folded window's folds on each plugin edit
- Location: carat/domain/buffer.rb:794
- Why: mark_folds allocates a Folds copy per folded window on every plugin edit_buffer, success included, for a rollback only a failure uses.
- Fix: acceptable as designed, or take the copy lazily on the first splice of the marked transaction that touches a tracked fold list.
- Category: editor
- Added: 2026-11-18

### Buffer#sign_at and sign_group_at have no production caller (sprint-18 review quality, sweep quality)
- Location: `carat/domain/buffer.rb:406`, `:415`; `carat/adapters/frame_presenter.rb:852` to `:858`.
- Why it matters: the presenter reads `layer_at(shown_layer_index(row))` itself, so the two readers serve only tests and the sign lookup has two shapes.
- Fix outline: one Buffer reader of the shown sign layer (or nil) used by the presenter and the tests, the test-only pair dropped, `shown_layer_index` private again.
- Also: carat/adapters/frame_presenter.rb
- Category: editor
- Added: 2026-11-18


### visibility: blanks is public though only first_nonblank and indent_of in at carat/domain/buffer.rb:538 (sprint-32 sweep quality, note 28)
- Location: carat/domain/buffer.rb:538
- Why: visibility: blanks is public though only first_nonblank and indent_of in the file use it
- Fix: move it below private
- Category: quality

### duplication: detect_filetype repeats assign_filetype's two writes (line 291) at carat/domain/buffer.rb:255 (sprint-32 sweep quality, note 29)
- Location: carat/domain/buffer.rb:255
- Why: duplication: detect_filetype repeats assign_filetype's two writes (line 291)
- Fix: detect_filetype calls assign_filetype(Filetype.detect(path, line(0)))
- Category: quality
