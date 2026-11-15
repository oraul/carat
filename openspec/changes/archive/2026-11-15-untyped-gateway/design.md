# Design

## Context

From Spinel 2440954d1 on, a call plan question during code generation (`elab_point_of`) rebuilds the load record whenever the node table changed since its last build, and each `[]` on an `untyped` receiver asks it twice (the `[]`, then a `new`). `SP_TIMING` counts the rebuilds as `phase=an_elab_points ... builds=N`. untyped-elephant (#124) typed the test tables' rows and left 1,181 rebuilds at 6b43fe94.

The measurement toolchain is the one untyped-elephant built: 6b43fe94 under `tmp/.spinel-new` and `tmp/.toolchain-new`, with a local trace in `elab_fresh` printed under `SP_ELAB_TRACE`, naming for each rebuild the method being generated and the call that asked. At main (56324bd), `make test-build PREFIX=tmp/.toolchain-new` with its own `SPINEL_CACHE_DIR` gives 1,181 builds, `an_elab_points` 94.1 s within `cg_methods` 151.9 s, analysis 118.3 s, 5 min 30 s in all (four cores). By generated method: the seven language-server tests 402, nearly all in their `main` and their `last_of` loops; `JsonRpcLanguageGateway` 210; `DomainGrammarTest` 62; `LintTest` 46; `EditorCmdlineTest` 36; FileUtils 26; `SymbolOutline` 18; the rest under 25 each.

## Goals / Non-Goals

**Goals:**

- Remove the largest cause, the language-server tests' untyped reads of the parsed bodies, with behavior and every snapshot unchanged and every stage green at 6af548c9.
- Readers in `Carat::Json` that the gateway's reads can use next.

**Non-Goals:**

- The gateway's own reads, `SymbolOutline`, the other test helpers and loops, the bundled packages.
- Changing Spinel or `SPINEL_REF`.

## Decisions

- Typed readers in `Carat::Json`, not a typed record per message. `field(value, key)` checks `is_a?(Hash)` and calls `object_field`, `(Hash[String, untyped], String) -> untyped`; `element(value, index)` checks `is_a?(Array)` and calls `array_element`, the element reader `(Array[untyped], Integer) -> untyped` that `lint` allows. Each body is generated once and its `[]` is on a typed receiver, so no call of them rebuilds. Alternative: records for each message kind (`Request`, `Position`), rejected as a rewrite of every check for the same effect, and the bodies the tests read are of a dozen shapes.
- `reach(value, path)` takes a dotted path, a segment of digits an array index, because the tests read chains five and six members deep (`params.capabilities.textDocument.completion.completionItem.snippetSupport`): one call per value read instead of nested `field` calls. Member names in the protocol hold no dot and are never all digits, so the path is unambiguous for them.
- A reader answers nil where `[]` would raise (a read of a member of nil or of an array): only a broken test changes, from an exception to a failed check with its label, never a passing one.
- The tests' reads were rewritten by a script, not by hand: each chain of string or integer index reads on a parsed body (`last_of(...)`, `last_body(h)`, `J.parse(...)`, or a local holding one) became `J.reach(base, "a.b.c")`, a single member read `J.field(base, "a")`. The script stays out of the repository: the change is the rewritten calls. Every touched test keeps its snapshot, run at both commits.

## Risks / Trade-offs

- [`object_field` is called with a value Spinel trusts as a `Hash` unverified] → `field` checks `is_a?(Hash)` first, and the helper is called from nowhere else.
- [The figures depend on the Spinel commit] → The rebuild count is deterministic for a commit and the source; the seconds are machine dependent and given only beside it.

## Migration Plan

None: one module gains readers and tests change, squash-merged as one commit.

## Open Questions

None.
