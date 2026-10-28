# Tasks

## 1. Verify Struct under Spinel

- [x] 1.1 Compile and run a probe program with the pinned Spinel, outside the repository, covering the subclass form with positional and keyword construction, readers and writers, `==`, `to_a`, `members`, `each_pair`, a custom `initialize` with `super`, an overridden `to_a`, inline RBS on the subclass's methods, `# @rbs @member` pins versus inference, `--emit-rbs` output, and frame and cell reuse under allocation pressure; record the results in design.md

## 2. Convert the simple records

- [x] 2.1 Convert `carat/domain/cursor.rb`, `window.rb`, and `cell.rb` to `Struct` subclasses with member pins, keeping `Cursor.new(row, col)`, `Window.new`, `Cursor#to_a`, and `Cell#same?`; verify with `make build` and `test/domain_buffer.rb`, `test/adapters_frame_presenter.rb`, `test/adapters_screen_presenter.rb`
- [x] 2.2 Convert `carat/domain/buffer.rb` and `options.rb`, keeping `Buffer.new(lines, path, line_ending)`, `Buffer.from_text`, `Options.new` with Vim's defaults, and `Options.from_config`; verify with `test/domain_buffer.rb` and `test/adapters_frame_presenter.rb`
- [x] 2.3 Add assertions to `test/domain_buffer.rb` for positional construction, readers and writers, `Cursor#to_a`, `members`, and `Window` and `Cursor` defaults; regenerate its snapshot with `make snapshots` and review the diff

## 3. Convert the composite records

- [x] 3.1 Convert `carat/domain/frame.rb` to a `Struct` subclass whose `initialize(rows, cols)` builds the cell grid, keeping `cell`, `clear`, `put`, `fill`, `row_text`, `text_rows`, `sync_from`, and `row_same?` unchanged in behavior; verify with `test/adapters_frame_presenter.rb`, `test/adapters_screen_presenter.rb`, and `test/editor_screen.rb`
- [x] 3.2 Add an assertion to `test/adapters_frame_presenter.rb` that a second render of the same size returns the same frame and the same cell objects; regenerate its snapshot with `make snapshots` and review the diff
- [x] 3.3 Convert `carat/domain/editor_state.rb`, keeping `EditorState.new(buffer, options, timeoutlen)`, `show`, `clear_message`, `current_line`, `max_col`, and `load`; verify with `test/use_cases_ex.rb` and the `test/editor_*.rb` programs
- [x] 3.4 Convert `Keymap` and `KeymapNode` in `carat/domain/keymap.rb`, keeping `Keymap.build`, `add`, `bind`, `lookup`, and the node's `child?`, `child!`, `leaf?`; verify with `test/domain_keymap.rb`

## 4. Conventions and documentation

- [x] 4.1 Update the convention in `CLAUDE.md` (coding conventions) and `docs/architecture.md` (section 2.1 and the section 4 entity list) so it reads: immutable values are `Data` subclasses, mutable records are `Struct` subclasses, both in the subclass form, and behavior classes are plain classes; verify by reading both documents against the code
- [x] 4.2 Add the delivery rule as the first hard rule of `CLAUDE.md` and the no-shortcut line to the mandate of `.claude/agents/contributor.md`; verify by reading both files

## 5. Verify

- [x] 5.1 Run `make check` (build, gen-config, test, diagnose) under Spinel with no inline RBS warning on build, and compare `make types` for every converted class against the output recorded before the conversion

## Workflow follow-up

- Archive the change with `--skip-specs` before the final push, then update pull request 8 and merge it once the `spin` check is green.
