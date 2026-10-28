# Proposal

## Why

The domain's immutable values (`Position`, `Range`, `ExCommand`, the key notation `Result`, `KeymapMatch`) and the use case boundary value `Outcome` were hand-written classes with their own constructors, readers, and, for `Position`, a hand-written `==`. Later roadmap items lean on these values heavily: the command grammar produces `Command` values, operators receive `Range` values, registers and marks key on positions, and tests compare them by value. Hand-written equality is easy to forget or get wrong, and none of these values were frozen. Ruby 4's `Data` gives value equality, hashing, immutability, and `with` for free, and a compiled probe confirmed that Spinel supports all of it. Doing the conversion now, before the grammar lands, keeps every later value type on one convention.

## What Changes

- `Position`, `Range`, `ExCommand`, `KeyNotation::Result`, and `KeymapMatch` become `Data` subclasses written as `class Name < Data.define(...)`, dropping their hand-written constructors, readers, and equality.
- `Outcome` in the use case layer becomes a `Data` subclass for the same reason.
- The convention is recorded in `CLAUDE.md` and `docs/architecture.md`: immutable values are `Data` subclasses in the subclass form, never the block form, because Spinel ignores inline RBS inside a `Data.define` block; anything that changes after construction stays a plain class.
- `make diagnose` skips the behavior leg of `spinel-doctor`, which compares the binary against a CRuby interpreter on the path. The project uses no CRuby, and Ruby 4 output (for example `Hash#inspect`) differs from Ruby 3, so the leg reports false errors.
- The buffer test gains assertions that pin the semantics relied on: value equality, hashing, hash-key lookup, frozenness, and `with` copies.

No editor behavior changes. No binding, message, or rendering is different.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None. This is a pure refactor; `skip_specs` is set for this change.

## Impact

- `carat/domain/position.rb`, `range.rb`, `ex_command.rb`, `key_notation.rb`, `keymap.rb`; `carat/use_cases/outcome.rb`.
- `test/domain_buffer.rb` and its snapshot.
- `Makefile` (`diagnose` target), `CLAUDE.md`, `docs/architecture.md`.
- No call site changes: every constructor was already called positionally and `Data` accepts positional arguments.
