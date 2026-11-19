# Proposal

## Why

Use cases expose 293 `attr_reader`s, almost all of them only so `test/adapters_assembly.rb` can check that every holder got the one shared object `EditorAssembly` built, and `lint`'s shared-holder rule requires a reader for every shared collaborator a holder stores. The readers widen each use case's surface past its one public `call`, and 22 of the 103 `call` signatures return no `Outcome`. The user's design: the public surface of a use case is `call` returning an `Outcome`, collaborators are read as instance variables, a private reader only where a concern needs one, and the guard reads a wiring ledger `EditorAssembly` fills.

This is part a of 4 of a user-requested tidy-up outside the roadmap of `docs/architecture.md` section 12: it changes how the core is wired and checked, not what the editor does.

## What Changes

- `carat/adapters/wiring_ledger.rb` (new): `WiringLedger`, the record of what `EditorAssembly` handed each holder: `record(holder, slot, object)`, `held(holder, slot)` (nil for a pair never recorded), and `slots(holder)` in recording order.
- `carat/adapters/editor_assembly.rb`: builds the ledger first, keeps it in the `wiring` reader, and records, right after each discovery use case is built, every shared object it handed that use case, from the same instance variable it passed.
- The first area, `carat/use_cases/discovery/` (map area 5): `ShowKeyHints`, `HideKeyHints`, `OpenPalette`, and `FollowPalette` drop their 19 readers (7, 2, 7, 3) for `# @rbs @name: Type` lines; none of them was read by production code, none includes a concern, and every method already reads the instance variables. The use cases' readers go from 293 to 274.
- `test/adapters_assembly.rb`: the guard reads the discovery holders through `a.wiring.held(holder, slot)`, still by `equal?` through `strangers`, checks each holder's recorded slots against its constructor's keywords, and checks itself: a pair never recorded is a stranger.
- `test/lint.rb`, the shared-holder rule: a shared keyword a holder stores without a reader is accepted when the assembly records it in the ledger with the object its construction passed, and the assembly test names that `held` pair; a use case under a directory of `READERLESS_DIRS` (now `carat/use_cases/discovery/`) has no public reader. Self-tests cover each new branch.
- Edge-case tests first, in their own commit: the palette with a text of colons alone, a trailing blank in its text, and over an empty buffer (`test/editor_palette.rb`); a second Esc with no hints shown, the hints from the last line, and over an empty buffer (`test/editor_key_hints.rb`).
- `design.md` maps the 22 `call`s that return no `Outcome` to what each will return, for parts b to d.
- Docs: `docs/architecture.md` sections 8 and 10 and the use-case paragraph of section 5, `docs/codebase-map.md` (the new file, the assembly, the guard, area 5's use cases), `docs/examples.md` (the golden use case's readers), `docs/spinel-notes.md` and `CLAUDE.md` (the sentence on readers for the guard).

## Capabilities

### New Capabilities

None: the change alters how the core is wired and checked, no behavior (`skip_specs: true`).

### Modified Capabilities

None.

## Out of scope

- The other areas' 274 readers, the 5 production code reads (`show_hover.hover`, `follow_hover.hover`, `show_definition.definition`, `show_completion.source`, `file_requests.files`), and the 22 `call` signatures: parts b to d, by the mapping in `design.md`. Discovery's three void `call`s (`ShowKeyHints`, `HideKeyHints`, `FollowPalette`) keep their signatures here.
- The adapters' readers (`InputController`, `FramePresenter`, the gateway) and the plugin host's request families: not use cases.
- No `tools/rules.sh` edit; no file of the feature lane.

## Impact

- CLAUDE.md: the Coding conventions sentence on shared objects says the guard reads the ledger for a readerless holder.
- docs/architecture.md: section 8's composition root paragraph, section 5's use-case paragraph (readers only where the guard still needs them, none in a readerless directory), and section 10's guard bullet name the ledger.
- README.md: unchanged, it describes neither the use cases' readers nor the shared-instance guard.
- docs/codebase-map.md: area 4 gains `carat/adapters/wiring_ledger.rb` and the guard's ledger checks; area 5's discovery entries are unchanged since they name no reader.
- Performance: no hot path changes (the ledger is written once at start); the pull request compares analysis time, rounds, binary size, and time per key with main's.
