# Tasks

## 1. The fact

- [x] 1.1 Print `ruby yes|no|unknown` from `tools/lane_facts.sh`; prove it in `tools/tools_test.sh` (lane_facts cases over carat/, bin/, bench/, config/, carat.rb, docs, tools, test)

## 2. The phase

- [x] 2.1 Parse it strictly in `parseLaneFacts`, add `noRubyAt` and `benchWithoutRuby`, and call it in the Benchmark phase after the equal-figures branch and before the agent (`.claude/workflows/deliver-change.js`); prove it in `tools/tools_test.sh` (a docs-and-tools-only diff records the bench review with no agent; a diff touching Ruby code, an unknown fact, a dirty lane, another head, or an unchecked head keeps the gate; the branch order)

## 3. Docs

- [x] 3.1 Update README.md and `docs/codebase-map.md`
- [x] 3.2 Append the findings to `docs/findings/bench-skip-nonruby.md`

## Quality review

- [x] 4.1 A `Makefile` or `tools/spinel/` change reads `ruby no`, so a Spinel bump skips the benchmark agent; outside the brief's paths, recorded in `docs/findings/bench-skip-nonruby.md`; fixed in 5.1
- [x] 4.2 The fact is relayed through a record start, as `machinery` is; a forged `no` would skip the gate; recorded in `docs/findings/bench-skip-nonruby.md` (a run-state command would need new code)

## Review round

- [x] 5.1 Read a `Makefile`, `tools/spinel/`, or `tools/metrics.sh` change as `ruby yes` so a Spinel bump or flag change keeps the benchmark gate (`tools/lane_facts.sh`, `tools/tools_test.sh`, README.md, `docs/codebase-map.md`); fixes task 4.1
- [x] 5.2 The relayed fact (task 4.2) needs a run-state command computing and recording it, which is new code outside this change's files; left, as recorded in `docs/findings/bench-skip-nonruby.md`
