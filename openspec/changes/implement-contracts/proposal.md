# Proposal

## Why

Quality passes first in 13 of the last 40 runs, and the contributor and the quality reviewer together take most of the requests; a blocker a mechanical check could have caught costs a whole round. The planner counts 8 of 40 recorded quality blockers behind four such checks: a changed `tools/` script with no new case (3), a shared object held without a reader the assembly test checks (2), a port method missing from the port table of `docs/architecture.md` section 6 (2), and a `has_`, `is_`, or `get_` member or keyword name (1). This is item 3 of `docs/queue.md`, outside the editor roadmap of `docs/architecture.md` section 12: it changes the lint test, the gates, and the assembly test only.

## What Changes

- (a) Predicate-like member names: `make lint` refuses an `attr_*` name, a `Struct` or `Data` member, or a keyword parameter of a `def` starting with `get_`, `is_`, or `has_`, as the method rule already does for def names.
- (b) The port table: `make lint` refuses a public method of a class under `carat/ports/` that its row of the table in `docs/architecture.md` section 6 does not name, a method the row names that the port does not define, and a port without a row. The table gains `LanguageServicePort#start`, the one method it misses today.
- (c) Shared holders: `make lint` refuses a class the assembly keeps in a reader that stores a keyword argument of a shared type (a type `EditorAssembly` keeps in a reader) without a reader of its own, and such a reader that `test/adapters_assembly.rb` never names after its holder (`.holder.reader`). `Dispatcher`, `HandleKey`, and `RepeatLast` gain the readers they miss, and the assembly test gains a strangers row for every holder the check finds unnamed.
- (d) Changed tools: `tools/gates.sh cases`, part of `static` (`make gates`) and `pre-push`, refuses a branch that changes a code line of a shell script under `tools/` other than `tools/tools_test.sh` without adding or changing an `expect` case in `tools/tools_test.sh`, naming the scripts.
- Bookkeeping: the backlog entries 'The dispatcher and HandleKey hold shared objects without readers' (fixed here) and 'The hover owner is spelled in two use cases' (stale: both use cases read `Domain::HoverRequest::OWNER`) are removed. The rest of queue item 3 (a map line naming an absent method, an `Array[untyped]` of objects with no list class, a def shadowing a reader, and the implement-step contracts) stays queued as `implement-contracts-b` in the planner's queue.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None: the change touches the lint test, the gates, and the assembly test, and no editor behavior, so it sets `skip_specs: true`.

## Out of scope

- The rest of queue item 3, queued as `implement-contracts-b`.
- Holders of shared objects nested below a class the assembly keeps (for example a handler's use cases, or `ShowCompletion`'s `CloseCompletion`): the holder check reads the assembly's own readers one level deep.
- A function-level reading of a `tools/` change: the gate works per script, since the cases call scripts by subcommand, not by function.

## Assumptions

- A shared type is a class `EditorAssembly` keeps in an `attr_reader`; a holder is named in the assembly test when the text `.holder.reader` appears there, with `host.` read as `a.plugins.`, the test's alias for the plugin host.
- A comment-only or blank-line change to a `tools/` script needs no case.

## Impact

- `test/lint.rb` (three rules and their self-checks), `test/adapters_assembly.rb`, `carat/use_cases/dispatcher.rb`, `carat/use_cases/handle_key.rb`, `carat/use_cases/repeat_last.rb`.
- `tools/gates.sh` (the `cases` gate), `tools/tools_test.sh`.
- `docs/architecture.md` section 6, `docs/codebase-map.md` areas of the touched files, `docs/backlog.md`; `docs/queue.md` and `docs/metrics.tsv` at the package step.
