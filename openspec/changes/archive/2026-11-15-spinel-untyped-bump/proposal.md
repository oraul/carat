# Proposal

## Why

From Spinel 2440954d1 on, each `[]` generated on a receiver Spinel types `untyped` makes code generation rebuild the load record, Spinel's map of where each statement runs, by walking the whole program, so `SPINEL_REF` stays at 6af548c9. untyped-elephant (#124) and untyped-gateway (#128) cut the test runner's rebuilds at 6b43fe94 from 4,501 to 779. The user asked for a bump to Spinel's newest commit with the rest removed so compile time stays near today's; the plan splits it into two pull requests, this one the untyped removal and `spinel-untyped-bump-b` the bump of `SPINEL_REF`. What remains, measured at main with the newest Spinel (b582d53e) traced in a separate toolchain under `tmp/`: the JSON reads of `JsonRpcLanguageGateway`, `SymbolOutline`, and the test helpers and loops that index untyped values (figures in design.md).

## What Changes

- `JsonRpcLanguageGateway` reads every parsed message, result, and notification through `Carat::Json.field` and `Carat::Json.element`, whose `[]` is on a receiver typed `Hash` or `Array`, instead of `[]` on the untyped value: the same values read, the same guards, the same answers.
- `SymbolOutline` reads the documentSymbol answer the same way.
- The test helpers and loops that index untyped values (`DomainGrammarTest`, `LintTest`, and the others the trace names above a few rebuilds) read them through a typed element reader or `Carat::Json`'s readers, every check, label, and snapshot unchanged.
- `docs/spinel-notes.md` records the figures after this change at the newest Spinel and at the pin.

No editor behavior changes: every read answers what `[]` answered for the values the guards let through, and every snapshot stays as it is.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None. No behavior changes, so `skip_specs` is set.

## Impact

- `carat/adapters/json_rpc_language_gateway.rb`, `carat/adapters/symbol_outline.rb`: their JSON reads.
- The test files the trace names (`test/domain_grammar.rb`, `test/lint.rb`, and others listed in tasks.md): their untyped indexing.
- `docs/spinel-notes.md`: the figures and the remaining causes.
- CLAUDE.md: unchanged, no command, agent, workflow, or rule changes.
- README.md: unchanged, no command, option, or user-visible behavior changes.
- docs/architecture.md: unchanged, no layer, port, or module changes.
- `SPINEL_REF` stays at 6af548c9 in this pull request; the measurements use the separate toolchain under `tmp/`.

Outside the roadmap of `docs/architecture.md` section 12: compile-time work the user asked for, so carat can follow Spinel past 2440954d1.

## Out of scope

- Moving `SPINEL_REF`, regenerating the vendored header, and the header generator's update: `spinel-untyped-bump-b`, the next pull request, after this one merges. At b582d53e the generator's Symbol check stops on nine names Spinel's own generator now lists as false positives; part b updates the port's list.
- The bundled FileUtils, not carat's code.
- The queue's order.

Assumptions recorded here instead of asked: the change is split as the plan says, this first part keeping the change's name; a test helper reads an untyped array through `Carat::Json.element` or a local element reader `(Array[untyped], Integer) -> untyped`, as `Testing#table` reads its rows through `cell`, rather than a new public `Carat::Testing` helper.
