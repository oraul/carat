# Tasks

## 1. The gateway skips a pathless buffer

- [x] 1.1 Change `carat/adapters/json_rpc_language_gateway.rb` (`sync`, `sync_buffer`, `complete`, `send_hover`, `send_signature`) to read the path through `Buffer#path_text` and skip `""`, proved by the sync, completion, hover, signature, publish, and written-to-a-name rows of a new `test/adapters_pathless_language.rb` (`make test-one T=test/adapters_pathless_language.rb`)

## 2. Records

- [x] 2.1 Register the test in `test/runner/run_all.rb` and on area 17's Tests line of `docs/codebase-map.md`, proved by `make lint` and `make docs-lint`
- [x] 2.2 Record the plan's bookkeeping in `docs/backlog.md`: remove the fixed entry, add the plan's entries, merge the two `HandleKey#timeout` entries, widen the README commands entry, and correct the `cls` line, proved by `make docs-lint`
- [ ] 2.3 Run `make gates`, `make spec-validate`, and the targeted tests; the gateway works only on idle ticks, so `lh` allocations per key are unchanged
