# Proposal

## Why

From Spinel 2440954d1 on, each `[]` generated on a receiver Spinel types `untyped` makes code generation rebuild the load record, Spinel's map of where each statement runs, by walking the whole program; `SPINEL_REF` stays at its parent 6af548c9 until carat stops feeding such receivers to `[]`. untyped-elephant (#124) removed the main cause, the test tables' rows, and left the runner at 1,181 rebuilds at 6b43fe94 against 39 at 6af548c9. Measured again at main (56324bd) with the traced 6b43fe94 toolchain under `tmp/`, the largest cause left is the language-server tests' reads of the bodies the editor sent, parsed with `Carat::Json.parse` (typed `untyped`) and indexed as `body["params"]["position"]["line"]`: 402 rebuilds (`AdaptersServerCompletionsTest` 122, `AdaptersLanguageGatewayTest` 90, `AdaptersSignatureTest` 60, `AdaptersHoverTest` 48, `AdaptersDefinitionsTest` 46, `EditorBreadcrumbsTest` 30, `EditorLspTest` 6), against 210 for the JSON reads of `JsonRpcLanguageGateway` itself, 18 for `SymbolOutline`, and the rest in other test helpers and loops.

## What Changes

- `Carat::Json` gains typed readers of a parsed value: `field(value, key)`, the member of an object; `element(value, index)`, the element of an array; and `reach(value, path)`, a dotted path of members and array indexes (`"params.contentChanges.0.text"`). Each answers nil for a value of another kind or a step that finds nothing, and its `[]` is on a receiver typed `Hash[String, untyped]` or `Array[untyped]`, so a call costs no rebuild.
- The seven language-server tests read the parsed bodies through `field` and `reach` instead of chained `[]`: the same values, the same checks, labels, and snapshots.
- `docs/spinel-notes.md` names the readers and the figures after this change; `docs/codebase-map.md` names the readers.

No editor behavior changes: the readers are new and only the tests call them, and every snapshot stays as it is.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None. No behavior changes, so `skip_specs` is set.

## Impact

- `carat/domain/json.rb`: `field`, `element`, `reach`, and their typed helpers `object_field`, `array_element`, `digits?`.
- `test/json.rb`: three checks of the readers.
- `test/adapters_server_completions.rb`, `test/adapters_language_gateway.rb`, `test/adapters_signature.rb`, `test/adapters_hover.rb`, `test/adapters_definitions.rb`, `test/editor_breadcrumbs.rb`, `test/editor_lsp.rb`: their body reads.
- `docs/spinel-notes.md`, `docs/codebase-map.md`.
- CLAUDE.md: unchanged, no command, agent, workflow, or rule changes.
- README.md: unchanged, no command, option, or user-visible behavior changes.
- docs/architecture.md: unchanged, section 10 describes the test machinery without naming the JSON readers.
- `SPINEL_REF` stays at 6af548c9; the 6b43fe94 measurements use the separate toolchain under `tmp/` untyped-elephant built.

Outside the roadmap of `docs/architecture.md` section 12: compile-time work the user asked for, so carat can follow Spinel past 2440954d1.

## Out of scope

- The gateway's own JSON reads (210 rebuilds), the next cause: they change production code of the language gateway, and the brief asks for the largest cause only. The readers added here are what they would use.
- `SymbolOutline` (18), the other test helpers and loops that index untyped values (`DomainGrammarTest` 62, `LintTest` 46, and others), and the bundled packages (FileUtils 26).
- Changing Spinel or `SPINEL_REF`; the queue's order.

Assumptions recorded here instead of asked: the change keeps its name although its larger cause is the tests rather than the gateway, as the brief and the plan say to remove whichever is larger; the readers live in `Carat::Json`, the one JSON module, rather than in each test, so the gateway can use them next.
