# Tasks

## 1. Measure

- [ ] 1.1 Measure `make test-build` at main with the traced 6b43fe94 toolchain under `tmp/` (`PREFIX=tmp/.toolchain-new`, `SP_ELAB_TRACE=1`, its own `SPINEL_CACHE_DIR`) and at the pinned 6af548c9: the `an_elab_points` builds, the `cg_methods` seconds, and the rebuilds per generated method, to name the largest cause left (the gateway's JSON reads or the language-server tests' indexing).

## 2. The typed readers

- [ ] 2.1 `carat/domain/json.rb`: add `Json.field`, `Json.element`, and `Json.reach`, typed readers of a parsed value whose `[]` is on a receiver typed `Hash` or `Array`, nil for a value of another kind. Proven by `test/json.rb` ("a dotted path reads members and elements, nil where a step finds none", "a member or an element of another kind of value is nil", "a path segment of digits is an index"); `make test-one T=test/json.rb`.

## 3. The largest cause

- [ ] 3.1 Read the parsed bodies of the largest cause through the typed readers, behavior and every snapshot unchanged. Proven by the touched tests' unchanged snapshots (`make test-one` for each) and by the traced build at 6b43fe94, where that cause's rebuilds vanish.

## 4. Measure again and document

- [ ] 4.1 Measure `make test-build` again at both commits, and `make test` at 6af548c9 with every snapshot unchanged and re-narrowing at 2 rounds.
- [ ] 4.2 `docs/spinel-notes.md`: the figures after this change and the readers that avoid the construct; `docs/codebase-map.md` names the readers. Verify with `make docs-lint`, `make gates`, and `make spec-validate`.
