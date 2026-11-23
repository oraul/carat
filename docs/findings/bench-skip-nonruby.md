### A Spinel bump or Makefile build flag change skips the benchmark agent
- Location: `.claude/workflows/deliver-change.js` (`benchWithoutRuby`) and `tools/lane_facts.sh` (the `ruby` fact)
- Why: the brief names only `carat/`, `bin/`, `bench/`, `config/`, and `carat.rb` as Ruby code, so a diff of the `Makefile` (`SPINEL_REF`, build flags) or `tools/spinel/` alone reads `ruby no` and records the bench review with no agent, though a new compiler or flag can change allocations and rounds; CI's metrics stage still compares them on the pull request.
- Fix: add `Makefile`, `tools/spinel/`, and `tools/metrics.sh` to the pattern of the `ruby` fact (and its tools-test cases), or keep the gate when the `Makefile` diff touches `SPINEL_REF`.
### The ruby fact is relayed through a record start
- Location: `.claude/workflows/deliver-change.js` (`laneHead`, `noRubyAt`)
- Why: the workflow has no shell, so a runner start relays `tools/lane_facts.sh`, as for `machinery`; a forged `ruby no` would record the bench review passed. The parse is strict (`yes` or `no`, else `unknown`) and the lane must be clean at the check's head, but the relay itself is trusted.
- Fix: have `tools/run_state.sh` record the fact itself (a `ruby-scope` command the runner calls and the review gate reads) so no model output carries the decision.
