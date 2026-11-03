# Proposal

## Why

Every record of the domain is built with positional arguments today: `Window.new(buffer)` is readable, but `Range.new(from, to, :charwise, false)`, `Motion.new(target, true, false, -1)`, `Edit.new(0, 0, 1, 0, "x")`, or a `super(false, false, 8, 8, false, false, 0, "nerd", 1000, 1000, ...)` with twelve members say nothing about which value is which, and a positional `Struct` silently fills the members a call leaves out with `nil`. The user asked for every `Struct` record to be built with `keyword_init`, and approved this change in the core-quality queue.

## What Changes

- Every `Struct.new(...)` under `carat/` (37 records) gains `keyword_init: true`, and so do the two records the tests define (`test/domain_buffer_list.rb`, `test/use_cases_ex.rb`). A positional construction of a `Struct` record then raises `ArgumentError`.
- Every custom `initialize` of a `Struct` record takes required keyword parameters, with its signature in keyword form (`#: (row: Integer, col: Integer) -> void`), and calls `super` with keywords; a record whose default is an empty collection of a non-integer element type keeps `super()` and the writers, because an empty literal passed through `super` is typed `Array[Integer]`.
- Every construction site of a `Struct` record in the library, the plugins, the tests, `bench/`, and `bin/` passes keywords.
- `Data` values are constructed with keywords too, at every call site, so one rule covers both record kinds: a record is built with keyword arguments. `Data` definitions do not change, since `Data.define` already accepts keywords. Spinel compiles a keyword construction of a `Data` value to the same C as a positional one (probed on the pinned compiler: both lower to the same `sp_Position_new(row, col)` call), so the choice costs nothing at run time; design.md records the measurements.
- `test/lint.rb` gains the record rules: every `Struct.new` under `carat/` and `test/` carries `keyword_init: true`, and every construction of a record class (`Name.new(...)` of a class declared with `Struct.new` or `Data.define`, and a bare `new(...)` inside a record's own file) passes keyword arguments; the constructor rule, which skipped record files, now covers their `initialize` too. Each rule is asserted against a good and a bad case.
- `CLAUDE.md` (the record convention, the trap note, and the lint description), `docs/architecture.md` (section 2.1 and the lint description), and `docs/plugins.md` (the plugin API values, `Manifest` above all, are built with keywords; the 1.3 note about the positional `filetypes` member) describe the keyword rule.

No editor behavior changes: every key, ex command, message, and screen stays the same, and every test snapshot stays the same.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None. This is a refactor of how records are built; `skip_specs` is set for this change.

## Impact

- `carat/domain/*.rb`, `carat/use_cases/**/*.rb`, `carat/adapters/*.rb`, `carat/doubles/*.rb`, `carat/plugins/**/*.rb`, `carat/plugin_api.rb` callers: record definitions and construction sites.
- `test/*.rb`, `bench/keys.rb`: construction sites; `test/lint.rb`: the record rules.
- `CLAUDE.md`, `docs/architecture.md`, `docs/plugins.md`.

This change is outside the roadmap of `docs/architecture.md` section 12: it is a code-quality refactor the user asked for and approved in the queue before more features.

Out of scope: changing any `Data` definition; adding keyword construction to behavior classes, which already take required keywords; renaming members; any change to the plugin API's version, since its values accept keywords already and the API's shape is the same; and any behavior change.

Assumptions recorded here instead of asked: the two `Struct` records the test programs define follow the rule too, since the request says every `Struct` record; `TabList`'s first window is passed as `window:`, the only parameter renamed, because `first:` reads poorly at the call site; the plugin documentation is updated to show keyword construction, which plugins outside this repository may keep or change at will, since `Data` accepts both forms and this repository's lint covers only its own code.
