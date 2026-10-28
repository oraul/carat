# Design

## Context

See proposal.md for motivation. `docs/architecture.md` already names these values as entities and fixes the Spinel rules; this design records what a compiled probe established about `Data` under the pinned Spinel commit:

- `Data.define` with keyword and positional construction, `ArgumentError` on a missing member, `==`, `eql?`, equal hashes for equal values, `uniq` by value, and lookup in a Hash by an equal but distinct instance all behave as in CRuby. The hash-key case matters because Spinel does not dispatch user-defined `hash` and `eql?` for hash keys, while `Data`'s built-in ones work.
- Instances are frozen; writing an instance variable raises `FrozenError`.
- `with`, `to_h`, `members`, `inspect`, and pattern matching in the hash and array forms work.
- A subclass of a `Data.define(...)` call is a static class: its methods take inline RBS signatures and Spinel infers the member types. Inline RBS inside a `Data.define do ... end` block is ignored with a compiler warning.
- `spinel-doctor`'s behavior leg runs the program under whatever `ruby` is on the path and diffs the output. With Ruby 3.3 on the path the only difference for the probe was `Hash#inspect` style, which is a Ruby 3 versus Ruby 4 difference, not a Spinel defect.

## Goals / Non-Goals

**Goals:**

- One convention for immutable values that every later entity (`Command`, register entries, marks, cells of the compatibility table) follows.
- No behavior change and no call site change.

**Non-Goals:**

- Converting mutable state. `Buffer`, `Cursor`, `Window`, `Frame`, `Cell`, `Options`, `EditorState`, and `Keymap` change after construction and stay plain classes. `Frame` and `Cell` are reused across renders on purpose, after allocation churn was found to corrupt buffers under Spinel's garbage collector.
- Changing any spec.

## Decisions

- Subclass form only, `class Position < Data.define(:row, :col)`, so inline RBS applies and the lint rule that every method carries a signature stays meaningful. Alternative: the block form with a constant; rejected because its RBS comments are ignored.
- Keep `Position#before?` and `Position#to_a`, drop its hand-written `==`; `Data` equality replaces it. `Range` keeps `charwise` and `normalized`, which now use the readers instead of instance variables.
- `Outcome` is converted although it lives in the use case layer, because it is the same kind of boundary value and the convention should not stop at the domain directory.
- `make diagnose` passes `--skip behavior`. Alternative: keep the leg and accept false errors; rejected because a check that must report clean cannot have known false positives, and the project's rule is that CRuby is never used.

## Risks / Trade-offs

- A `Data` member cannot be pinned with a `# @rbs @name: Type` line the way a plain class's instance variable can; the types come from inference. The `make types` output shows them inferred correctly for every converted class, so this is acceptable until a case appears where inference widens a member.
- Skipping the behavior leg removes one independent check of compiled output. The whole-editor tests and the pseudo-terminal smoke test cover the behaviors that matter, under Spinel itself.
