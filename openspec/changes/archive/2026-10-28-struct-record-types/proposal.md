# Proposal

## Why

The domain's mutable records (`Buffer`, `Cursor`, `Window`, `Frame`, `Cell`, `Options`, `EditorState`, `Keymap`, `KeymapNode`) are hand-written classes whose state is a set of fields with `attr_reader` or `attr_accessor` lines and a constructor that copies arguments into instance variables. The immutable values just became `Data` subclasses; the rule that pairs with it, mutable records are `Struct` subclasses, completes the convention before the command grammar, the undo tree, registers, and windows add a dozen more records. A compiled probe under the pinned Spinel confirmed that the `Struct` subclass form, custom constructors with `super`, member pins, and reuse of one record across thousands of renders all behave as needed.

## What Changes

- `Buffer`, `Cursor`, `Window`, `Frame`, `Cell`, `Options`, `EditorState`, `Keymap`, and `KeymapNode` become `Struct` subclasses written as `class Cursor < Struct.new(:row, :col, :want_col)`, dropping their `attr_*` lines and the instance variable copies in their constructors. Every method keeps its name and behavior; a constructor that takes fewer arguments than there are members (`Cursor.new(row, col)`, `Window.new`, `Options.new`, `Frame.new(rows, cols)`, `EditorState.new(buffer, options, timeoutlen)`, `Keymap.new`, `KeymapNode.new`) keeps its arity and fills the rest through `super`.
- `Frame` and `Cell` stay reusable across renders: `Frame#clear`, `Frame#put`, `Frame#sync_from`, and the presenters' reuse of one frame and one shadow frame are unchanged, so a render still allocates no cells.
- The convention in `CLAUDE.md` and `docs/architecture.md` now reads: immutable values are `Data` subclasses, mutable records are `Struct` subclasses, both in the subclass form, and behavior classes (use cases, adapters, drivers, ports, `Carat::Json`, `Carat::Testing`) are plain classes. The architecture's entity list marks each converted entity as a `Struct` record.
- The buffer and frame presenter tests gain assertions that pin the `Struct` semantics the code relies on: positional construction, readers and writers, `Cursor#to_a` staying `[row, col]`, `members`, and that a frame's cells are the same objects after a second render.
- `CLAUDE.md` gets a first hard rule that every change is delivered by the `contributor` agent through the OpenSpec loop and that a pull request without its archived OpenSpec change is not mergeable, and the agent's mandate says there is no shortcut for small changes.

No editor behavior changes. No binding, message, or rendering is different.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None. This is a pure refactor; `skip_specs` is set for this change.

## Impact

- `carat/domain/buffer.rb`, `cursor.rb`, `window.rb`, `frame.rb`, `cell.rb`, `options.rb`, `editor_state.rb`, `keymap.rb`.
- `test/domain_buffer.rb`, `test/adapters_frame_presenter.rb`, and their snapshots.
- `CLAUDE.md`, `docs/architecture.md`, `.claude/agents/contributor.md`.
- No call site changes: every constructor keeps its arity and every reader and writer keeps its name. `Struct` adds a writer for the fields that were read-only (`Buffer#lines`, `Buffer#line_ending`, `Frame#rows`, `Frame#cols`, `Keymap#errors`) and public readers for the fields that were private (`Frame#cells`, `Keymap#roots`, `KeymapNode#children`); nothing uses them.

This change is outside the roadmap of `docs/architecture.md` section 12: it is a convention refactor between items 2 and 3, done now so that item 3 and every later item write their records on the finished convention.

Out of scope: use cases, adapters, drivers, doubles, ports, `Carat::Json`, and `Carat::Testing`, which are behavior classes and stay plain; `Data` values, already converted; any new entity.

Assumptions recorded here instead of asked: the read-only fields above may gain a writer and the private collections above may gain a public reader, since `Struct` offers no way to withhold them and no caller uses them; `Cursor#to_a` keeps returning `[row, col]`, overriding `Struct#to_a`, because the harness and the ex command tests read it that way; member order follows the old constructor order.
