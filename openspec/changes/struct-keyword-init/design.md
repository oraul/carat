# Design

## Context

The coding conventions of `CLAUDE.md` said that records keep positional construction: `Struct` records were defined as `class Cursor < Struct.new(:row, :col, :want_col)` and built as `Cursor.new(0, 0)`, and `Data` values as `Position.new(0, 0)`. Positional construction hides which value goes to which member, and a positional `Struct` fills the members a call leaves out with `nil` without a word. The user asked for every `Struct` record to be built with `keyword_init`. The main session probed the pinned Spinel before the change: `keyword_init: true` compiles clean, the `# @rbs @member: Type` pins still apply, readers, writers, `==`, and `inspect` work, a custom `initialize(lines:, path:)` that calls `super(lines: lines, path: path, modified: false)` is fully typed, and a positional construction raises `ArgumentError`. The known trap remains: an empty array literal passed through `super` is typed `Array[Integer]`, so a member pinned to another element type fails the C compile unless the record calls `super()` and stores the literal through its writer.

## Goals / Non-Goals

Goals:

- Every `Struct` record under `carat/`, and the two the tests define, is declared with `keyword_init: true`, and every construction of one passes keywords.
- One rule for both record kinds, decided on measurements, and enforced by the lint test as far as it is mechanically checkable.
- The analysis stays at 2 re-narrowing rounds, the benchmark within 10 percent of 9edf2a3 on `lh`, `j`, `insert`, `dd`, and `undo`, and the allocation budget passes.

Non-Goals:

- Changing a `Data` definition, a member, or the plugin API's version.
- Any behavior change.

## Decisions

### Custom initializers take keywords and call super with keywords

Each custom `initialize` keeps its parameters, as required keywords, with a keyword signature (`#: (rows: Integer, cols: Integer) -> void`), and passes keywords to `super` (`super(row: row, col: col, want_col: col)`). The lint test's constructor rule, which skipped record files, now covers them. The only parameter renamed is `TabList`'s `first`, now `window:`, because `TabList.new(first: window)` reads poorly. Records whose defaults are empty collections keep what they did: the ones that already call `super()` and store through the writers stay so (`Keymap`, `Transaction`, `UndoTree`, `BufferList`, and others), and the ones that pass empty literals through `super` pass integer arrays only (`Runs`, `SentenceStarts`, `Frame`, `CommandGrammar`, `BlockInsert`, `LayoutNode`, `Walker`) or a hash (`KeymapNode`, `Registers`), which compile as before.

### Data values are built with keywords too

`Data.define` accepts both forms, so the question was only which rule the call sites follow. Spinel lowers `Position.new(row: i, col: i + 1)` and `Position.new(i, i + 1)` to the same C, a call of `sp_Position_new(lv_i, sp_int_add(lv_i, 1LL))`, in a probe on the pinned compiler, so the choice cannot change the run time or the allocations; the measurements below confirm it on the whole editor. With the cost settled, one rule for both kinds is simpler to state, to check, and to follow than two: a record is built with keyword arguments. It also helps most where positional construction hurt most: `Range.new(from: a, to: b, kind: :charwise, inclusive: false)`, `Motion.new(target: t, linewise: true, inclusive: false, want: -1)`, the plugin manifest with its ten members, and `Edit`'s four integers. `Data` definitions do not change.

### The lint rules

`test/lint.rb` gains two rules, each a function asserted against a good and a bad case:

- `struct_problem`: a line declaring `< Struct.new(` without `keyword_init: true)` is refused, under `carat/`, `bin/`, `test/`, and `bench/`.
- `construction_problem`: the record class names are read from every `< Struct.new(` and `< Data.define(` declaration; a line of code (strings emptied, comments dropped) that calls `Name.new(` of a record name, or a bare `new(` in a file that declares a record, must start its arguments with `name:` or close them empty; when the arguments start on the next line, as the plugin manifests do, that line is read instead. The name must not be the tail of a longer word, so `LayoutNode.new(` is not read as `Node.new(`.

A `Struct` construction that the lint missed would still raise `ArgumentError` when a test runs it; a `Data` construction would not, which is why the call-site rule exists.

### The rewrite

The call sites were rewritten by a throwaway script outside the repository that maps each positional argument to its member, or to its `initialize` parameter for a record with a custom one, rewriting nested constructions from the inside out; the compiler, the lint rule, and the tests check the result. No Ruby interpreter was used.

## Measurements

Filled in by the implementation; see the tasks.

## Risks / Trade-offs

- Longer call lines, especially `Position.new(row: r, col: c)` in hot code; no cost at run time, as measured.
- Plugins outside this repository may keep positional `Data` construction, which Ruby and Spinel still accept; only this repository's code is linted.

## Migration Plan

None: the change is internal, and every snapshot stays the same.
