# Design

## Context

See proposal.md for motivation. The previous change made the immutable values `Data` subclasses and recorded why the subclass form is required. This design records what a compiled probe (a standalone program outside the repository, compiled and run with the pinned Spinel commit, then checked with `--emit-rbs` and `spinel-doctor`) established about `Struct` under Spinel:

- The subclass form `class Cursor < Struct.new(:row, :col, :want_col)` compiles with no warning. Positional construction (`Window.new(0, 0)`), keyword construction on a plain `Struct` (`Window.new(top: 5, left: 6)`), and `keyword_init: true` all work. A wrong positional arity raises `ArgumentError`.
- Readers, writers from outside (`c.col = 9`), writers through `self` inside a method (`self.left = col`), `[]` and `[]=` by symbol and index, `==` and `eql?` by value, equal `hash` for equal values, `to_a`, `to_h`, `members`, `each_pair`, `inspect` as `#<struct Window top=5, left=6>`, `dup` as a copy, and `is_a?(Struct)` all behave as in CRuby. Instances are not frozen.
- A subclass may define `initialize` with a different arity and call `super(...)` with the full member list; the members are filled from the `super` arguments. Class methods (`def self.from_text`), private methods, a member that starts `nil`, a member holding a `Hash` of nodes of the same class, and a member holding an array handed in from outside and mutated in place (`lines[from...to] = new_lines`, `lines << ""`) all work.
- A user-defined `to_a` on the subclass overrides `Struct#to_a` unconditionally and is the one called.
- Inline RBS signatures on the subclass's methods apply: `--emit-rbs` prints them as written. Spinel lays the members out as instance variables and prints them as `@row: Integer` and so on, so `make types` shows a `Struct` member exactly as it shows a plain class's instance variable.
- `# @rbs @member: Type` lines pin `Struct` members. Without a pin, a member is inferred from what is stored, and a member that holds mixed values widens to `untyped`, which a signature on a method that writes it does not narrow. A pin is trusted without verification: a probe member pinned `String` that held an Integer printed empty, so a pin must describe what the program stores. A pin block warns and does not apply when the class body has no statement, exactly as for a plain class, so every record keeps at least one method.
- An empty array literal passed to `super` is typed `Array[Integer]` by default, and a `# @rbs @member: Array[String]` pin on the receiving member does not coerce it there: the C compile fails with an incompatible pointer type. The same literal assigned through the writer (`self.errors = []` after `super()`) is coerced by the pin, exactly as `@errors = []` is in a plain class. Without the pin the member compiles but `make types` shows it as `untyped`. An empty hash literal is typed `Hash[String, untyped]` by default and matches a pin whose value type is not a builtin, such as `Hash[String, KeymapNode]`.
- Reuse under allocation pressure: one `Frame` of `Cell` structs was cleared and repainted three thousand times while garbage was allocated between renders, and ended with the expected text and the same cell objects it started with. `spinel-doctor` reported clean on the probe.

Spinel's limitations document says a `Struct` subclass works, `Struct.new` with a string name is refused, `define_method` under a runtime condition inside the block is refused, and singleton methods on a `Struct` instance are refused. None of those forms is used.

## Goals / Non-Goals

**Goals:**

- One convention for mutable records that every later entity (`Selection`, `Transaction`, `UndoTree`, `Registers`, `Marks`, `Layout`, `TabPage`) follows.
- No behavior change and no call site change.
- The frame and cell reuse property stays intact: a render allocates no cells and the shadow frame is synced in place.

**Non-Goals:**

- Converting behavior classes. Use cases, adapters, drivers, doubles, ports, `Carat::Json`, and `Carat::Testing` have methods, not records, and stay plain classes.
- Changing any spec.

## Decisions

- Subclass form only, `class Cursor < Struct.new(:row, :col, :want_col)`, for the same reason as `Data`: inline RBS applies to the subclass's methods and the lint rule stays meaningful. Alternative: `Cursor = Struct.new(...) do ... end`; rejected because inline RBS inside the block receives no pins.
- Member order follows the old constructor order, and a constructor that took fewer arguments keeps its arity and fills the rest in `super`: `Cursor.new(row, col)` passes `want_col = col`, `Window.new` passes `0, 0`, `Options.new` passes Vim's defaults, `Frame.new(rows, cols)` builds the cell grid and passes it, `EditorState.new(buffer, options, timeoutlen)` passes a fresh window and cursor and the empty command line, `KeymapNode.new` passes `nil` and an empty hash. `Keymap.new` is the one exception: its empty error list is an `Array[String]`, which the probe showed cannot be passed to `super` as an empty literal, so it calls `super()` and stores both collections through the writers. Alternative: change the call sites to pass every member; rejected because the proposal promises no call site change and the defaults are part of the record's meaning.
- Every member gets a `# @rbs @member: Type` pin in the block at the top of the class, replacing the trailing `#: Type` of the old `attr_*` line, so `make types` keeps showing the same member types as before. After the conversion, `make types` was compared class by class against the output recorded before it: every member type is identical, each `initialize` now reports `void`, and the only additions are the `each`, `each_pair`, and `each_with_index` methods `Struct` provides. The pins for `Frame#cells`, `Keymap#roots`, and `KeymapNode#children` are kept as they were, including the ones Spinel widens to `untyped` because their element type is not a builtin.
- Methods use the readers and the `self.member =` writers, never instance variables, because that is what `Struct` defines and what Ruby semantics guarantee; a bare `member = x` inside a method would create a local.
- `Cursor#to_a` is kept and returns `[row, col]`, overriding `Struct#to_a`, because `EditorHarness#cursor` and the ex command tests compare it to a two-element array. Alternative: drop it and let `Struct#to_a` return three elements; rejected as a behavior change.
- `Cell#same?` stays as the explicit per-field comparison the presenters use, although `Struct#==` would do the same, so the hot path in `Frame#row_same?` keeps a monomorphic call on a known class.
- The delivery rule is reinforced in the same change because the request that launched it asked for both in one pull request: a first hard rule in `CLAUDE.md` and one line in the agent's mandate.

## Risks / Trade-offs

- [`Struct` adds writers for fields that were read-only and public readers for collections that were private] → Nothing uses them, the proposal records the widening as an assumption, and the dependency rule still keeps every layer from reaching a record it should not.
- [A pin that misdescribes a member corrupts the value silently] → Every pin copies the type from the old `attr_*` line or `# @rbs` block, and `make types` is compared before and after the conversion for every converted class.
- [`Struct#==` makes records equal by value where identity equality applied before] → No code compares two records with `==` or uses one as a hash key; `grep` over `carat/` and `bin/` confirms it.
- [`Struct` could change allocation behavior in the render loop] → The probe exercised reuse under garbage pressure, the presenters' reuse code is untouched, and the frame presenter test asserts that a second render reuses the same frame and cell objects.
