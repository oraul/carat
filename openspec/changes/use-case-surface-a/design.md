# Design

## Context

`EditorAssembly` builds every shared object once and hands it by keyword to each holder; `test/adapters_assembly.rb` proves by `equal?` that each holder got that one object, because a keyword default would build a second one silently. Today the guard reads each holder's object through a public reader, and `lint`'s shared-holder rule (`holder_problems`) requires one for every shared keyword a holder stores. Of the use cases' 293 readers, 222 are read by the guard by the scout's count (the queue line says 227; the scout's pattern skipped the `host.` chains), 5 by production code, and the rest by nothing.

## Goals / Non-Goals

Goals: a ledger the guard reads in place of the readers, a lint rule that keeps the ledger complete and true, the first area with no public reader, and the mapping of the 22 `call`s that return no `Outcome`.

Non-goals: the other areas, the production reads, and the `call` signatures, which parts b to d deliver.

## Decisions

### The first area: discovery

`carat/use_cases/discovery/` (map area 5) holds 19 readers in 4 use cases, 0 after this change: `ShowKeyHints` 7, `HideKeyHints` 2, `OpenPalette` 7, `FollowPalette` 3. All 19 are read only by the guard, none of the 5 production reads is among them, no discovery use case includes a concern, and every method already reads the instance variables (a local such as `palette = @palette` shadows the reader name), so dropping a reader changes no line of behavior. The larger directories (plugins 43, files 25, completion 24, definitions 21, docs 20, windows 20) hold the production reads or the request families and come in parts b to d. Alternative: `syntax/` (2 readers) proves less of the ledger, since it holds one shared object.

### The ledger

`Adapters::WiringLedger` is a plain class in the adapters layer beside the assembly that fills it: parallel arrays of holder names and slot names (`Array[String]`), the objects in a pinned `Array[untyped]`, and an index from `"holder.slot"` to position (`Hash[String, Integer]`). `record(holder, slot, object)` appends, a second record of a pair replacing the first's object; `held(holder, slot)` answers the object or nil; `slots(holder)` answers the holder's slot names in recording order. The objects are of many classes, so the element is `untyped` and only `equal?` is called on it, in the test; the receiver of every `[]` is a typed array, which keeps the analysis free of the untyped-receiver cost of `docs/spinel-notes.md`. It is written only during `initialize`, once per editor, never on a key.

`EditorAssembly` builds the ledger before anything else, keeps it in the `wiring` reader, and records each holder's shared objects on the lines right after the holder's construction, from the same instance variables the construction passed.

Alternatives considered: a `wire` helper returning its argument inside the keyword list (`hints: @wiring.wire(...)`) would bind the record to the passed object, but it returns `untyped` into every constructor's parameter and widens their types program-wide; a public `wiring` method on each use case breaks the one-`call` surface the change exists for.

### Keeping the ledger true

A record written beside the construction could drift from it, so `lint`'s shared-holder rule now reads the assembly too: for each shared keyword a holder stores without a reader, the assembly must hold `@wiring.record("holder", "keyword", X)` where the holder's construction line passes `keyword: X`, and the assembly test must name `held("holder", "keyword")`. A missing record, a record of another object, and a record the test never checks each fail `make lint`. The guard also compares `slots(holder)` with the constructor's shared keywords, so a record of a slot that does not exist is caught at test time. A holder that keeps a reader is checked as before, so the areas parts b to d have not reached keep working.

`READERLESS_DIRS` in `test/lint.rb` lists the directories whose use cases have no public reader (a private reader only where a concern needs one, after `private`); it starts with `carat/use_cases/discovery/` and each later part adds its area.

### The 22 calls that return no Outcome

Part a changes none of them; parts b to d apply this mapping with their areas.

- The 16 that return nothing (`ArrangeView`, `Dispatcher`, `OpenCompletionPopup`, `ShowCompletion`, `ShowCompletionDocs`, `FollowDefinition`, `ShowDefinition`, `FollowPalette`, `HideKeyHints`, `ShowKeyHints`, `FollowHover`, `FollowSignature`, `RequestSignature`, `ShowHover`, `ShowSignature`, `HighlightView`): return `Outcome.none`, or the `Outcome` they report today where they report one; no caller reads the value, so no caller changes.
- `HandleKey` (`Symbol`: `:handled`, `:idle`, `:pending`, `:waiting`): returns an `Outcome`; the key's state moves to `Domain::InputState` (`pending?`, which exists, and a `waiting?` predicate), which `InputController` already holds and reads after the call.
- `OpenDefinitionFloat` (`Integer`, the float id): returns an `Outcome`; it writes the id into the `Domain::Definition` record it is given, whose `pick_id` and `float_id` its two callers set from the return value today.
- `FormatDocs` (`Domain::DocsText`), `FindMatch` (`Domain::SearchHit`), `ProbePath` (`Domain::PathInfo`), and `ListTree` (`Array[String]`): queries that other use cases call and no key or ex command runs, whose callers need the value. Each keeps its value-returning `call`, listed in a `lint` list of queries documented in `docs/architecture.md` section 5. Alternative: each writes its answer into a domain record its caller passes, as `OpenDefinitionFloat` will; rejected for these four since the callers branch on the value at once (`hit = @find_match.call(...)`, `info.refusal`) and a shared record would add a slot to read and reset.

## Risks / Trade-offs

- The ledger holds `untyped` objects: the guard can only compare identities, which is all it does.
- Two ways to satisfy the guard live side by side until part d; the lint rule names which one a holder uses.
- The measured figures (analysis time and rounds of both compile roots, the binary's size, and time per key) are compared with main's in the pull request.
