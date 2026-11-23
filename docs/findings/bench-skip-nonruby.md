
### Benchmark skip ignores Makefile, Spinel pin, and build flags (security Low, confidence 4)
- Location: tools/lane_facts.sh:81
- Why: the ruby fact once left out the Makefile (SPINEL_REF, build flags) and tools/spinel/, so a compiler bump or flag change could skip the benchmark agent with no local allocation or rounds comparison; CI's metrics stage still compares them. A gap in a quality gate, not a security boundary. A later commit on this branch added these paths to the pattern, so this entry stays only as a record of the review.
- Fix: keep Makefile, tools/spinel/, and tools/metrics.sh in the ruby pattern with matching tools-test cases, or keep the gate only when the Makefile diff touches SPINEL_REF.

### Benchmark skip decided from a relayed fact (security Low, confidence 3)
- Location: .claude/workflows/deliver-change.js:949
- Why: benchWithoutRuby decides from the lane_facts output relayed by a record start (an agent), so a forged "ruby no" line would record the bench review as passed without a benchmark. The parse is strict, the lane must be clean at the head where the check passed, and the machinery fact already trusts the same relay. Raised in three review rounds; the comment and note were updated to list every path the ruby fact reads, the relay itself is unchanged.
- Fix: have tools/run_state.sh compute and record the ruby fact itself, through a command the review gate reads, so no model output carries the skip decision.

### A check clone cannot prove a sprint's groom carrier, so a fix round after the records commit fails its gates stage
- Location: tools/run_state.sh clone_make and clone_drop (the carry drops build/plan), tools/gates.sh gate_findings and groom_row (sprint-row reads the plan marker)
- Why: the check runs in a clean clone with no build/plan, so for a branch whose records commit removed groomed findings, the gates stage sees no carrier and reports every removed entry as missing, although make gates in the lane passes; a fix round after the package step can never pass the check.
- Fix: run the check before the records commit, or let the clone receive the lane's plan marker and groom.txt read-only for the gates stage.
