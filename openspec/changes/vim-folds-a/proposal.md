## Why

Carat has no folds: `docs/compatibility.md` holds no fold row and `zf`, `zo`, `zc`, `za`, `zd`, `zE` do nothing, so a long buffer cannot be collapsed to the part being read. This is part a of the `vim-folds` user request in `docs/queue-feature.md` (Sprint 15 item 1), outside the numbered roadmap items of `docs/architecture.md` section 12, which are delivered.

## What Changes

- Manual folds per window, Neovim's `foldmethod=manual`: `zf{motion}` and `zf` in the visual modes create a closed fold over the lines; a fold crossing an existing one grows to contain it, and a fold inside another nests in it.
- `zo` opens the closed fold under the cursor, `zc` closes the innermost open fold under it, `za` toggles (opens on a closed fold, else closes), `zd` deletes the fold under the cursor (a closed one first, nested folds kept), and `zE` deletes every fold of the window. `zo`, `zc`, `za`, and `zd` with no fold under the cursor give `E490: No fold found`.
- A closed fold is drawn as one row, Neovim's default fold text `+--  N lines: text` with the leading blanks of its first line removed and the rest of the row filled with `·`, its line number in the gutter; the window scrolls and places the cursor counting it as one row.
- `j` and `k` pass a closed fold as one line, a count counting it once, and land on its first line.
- A linewise operator on a closed fold acts on all its lines: `dd` deletes them, `2dd` the fold and the line after it, `dj` the fold and the next line, `yy` yanks them.
- The folds move with the buffer's edits: lines inserted above shift them, lines inserted inside extend them, deleted lines shrink them, and a fold whose lines are all deleted is gone.
- The keys are bound in `config/default.caratrc`: `zf` in normal and the visual modes, `zo`, `zc`, `za`, `zd`, `zE` in normal and the visual modes.

## Capabilities

### New Capabilities

- `folds`: manual folds per window, the fold keys, the one-row drawing, and how motions and operators treat a closed fold.

### Modified Capabilities

None.

## Impact

- Domain: new `Folds` record (the window's folds, their nesting, shifting, and fold text); `Window` gains a `folds` member, copied by a split; `Buffer#splice` shifts the folds of the windows that track the buffer; `Motions.vertical` passes closed folds; `OperatorKind::FOLD`.
- Use cases: `Operate` creates a fold for `zf{motion}` and widens a linewise range over closed folds; new `ChangeFolds` (open, close, toggle, delete, eliminate, and the visual `zf`) and `FoldHandler`; `ArrangeView` places floats by the screen row.
- Adapters: `FramePresenter` draws a closed fold as one row and places the cursor by screen row; `EditorAssembly` wires the handler.
- Config: the fold keys in `config/default.caratrc`, mirrored by `make gen-config`.
- Tests: new `test/editor_folds.rb` (table-driven, over the editor and its screen) and `test/domain_folds.rb`.
- Docs: `docs/compatibility.md` rows, `docs/actions.md` rows, `docs/codebase-map.md` areas, `docs/architecture.md` (the window record and the folds).
- README.md: changed, its feature list names manual folds.
- docs/architecture.md: changed, the window record holds its folds.
- Out of scope: part b (`zR`, `zM`, `zj`, `zk`, `[z`, `]z`, `:fold`, `:foldopen`, `:foldclose`); `zF`, `zD`, `zO`, `zC`, `zA`, `zv`, `zx`, counts before `zo` and `zc`; every other `foldmethod`, `foldlevel`, `foldcolumn`, `foldtext`, `foldopen`, and the `Folded` highlight group (a fold row uses the normal colors); search, `G`, and jumps opening a fold; `H`, `M`, `L`, and the scroll keys counting a closed fold as one row; a charwise operator on a closed fold; folds kept for a buffer the window shows again (showing another buffer drops them).
- Assumptions: `zf` leaves the cursor on the first line of the fold; `zc` and `za` move the cursor to the first line of the fold they close, as Neovim's cursor adjustment does; `zf` and the fold keys are not repeated by `.`, as in Neovim.
