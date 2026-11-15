# Tasks

## 1. Measure

- [x] 1.1 Measure `make test-build` at main with the traced 6b43fe94 toolchain under `tmp/` (`PREFIX=tmp/.toolchain-new`, `SP_ELAB_TRACE=1`, its own `SPINEL_CACHE_DIR`) and at the pinned 6af548c9: the `an_elab_points` builds, the `cg_methods` seconds, and the rebuilds per generated method, to name the largest cause left (the gateway's JSON reads or the language-server tests' indexing).
  - Result at 6b43fe94: 1,181 builds (as recorded), `an_elab_points` 94.1 s, `cg_methods` 151.9 s, analysis 118.3 s, 5 min 30 s. The seven language-server tests 402 (`AdaptersServerCompletionsTest` 122, `AdaptersLanguageGatewayTest` 90, `AdaptersSignatureTest` 60, `AdaptersHoverTest` 48, `AdaptersDefinitionsTest` 46, `EditorBreadcrumbsTest` 30, `EditorLspTest` 6), `JsonRpcLanguageGateway` 210, `SymbolOutline` 18: the tests are the largest cause. At 6af548c9 (a worktree of main): 39 builds, `cg_methods` 15.6 s, analysis 134.4 s, 3 min 1 s.

## 2. The typed readers

- [x] 2.1 `carat/domain/json.rb`: add `Json.field`, `Json.element`, and `Json.reach`, typed readers of a parsed value whose `[]` is on a receiver typed `Hash` or `Array`, nil for a value of another kind. Proven by `test/json.rb` ("a dotted path reads members and elements, nil where a step finds none", "a member or an element of another kind of value is nil", "a path segment of digits is an index"); `make test-one T=test/json.rb`.
  - Result: the three checks pass; `make snapshots` added only their three lines to `test/json.rb.expected`.

## 3. The largest cause

- [x] 3.1 Read the parsed bodies of the largest cause through the typed readers, behavior and every snapshot unchanged. Proven by the touched tests' unchanged snapshots (`make test-one` for each) and by the traced build at 6b43fe94, where that cause's rebuilds vanish.
  - Result: the seven tests, rewritten by script (`J.reach(base, "a.b.c")`, `J.field(base, "a")`), pass with `make test-one` at 6b43fe94 and make no rebuild there; `make snapshots` at 6af548c9 changed no snapshot of theirs.

## 4. Measure again and document

- [x] 4.1 Measure `make test-build` again at both commits, and `make test` at 6af548c9 with every snapshot unchanged and re-narrowing at 2 rounds.
  - Result at 6b43fe94: 779 builds (from 1,181), `an_elab_points` 62.7 s (from 94.1), `cg_methods` 99.8 s (from 151.9), analysis 121.1 s, 4 min 2 s (from 5 min 30 s). At 6af548c9: 39 builds, `cg_methods` 14.2 s (from 15.6), analysis 137.1 s, re-narrowing 2 rounds; `make test` passes.
- [x] 4.2 `docs/spinel-notes.md`: the figures after this change and the readers that avoid the construct; `docs/codebase-map.md` names the readers. Verify with `make docs-lint`, `make gates`, and `make spec-validate`.
