### tools-test cannot exercise bench/run.sh
- Location: tools/rules.sh:97 (TOOLS_RE), bench/run.sh
- Why: a tools-test case that reads bench/run.sh fails the check that TOOLS_RE covers every path tools-test reads, so the benchmark runner's per-key arithmetic and its budget mode have no test; grep-long-files kept the grep key counts in tools/metrics.sh for that reason.
- Fix: add bench/run.sh to TOOLS_RE in its own change (an edit of the merge gate's rules goes first, alone), then add tools-test cases over a fake benchmark binary for per_key and --budget.

### The grep scenario runs twice in the fast stages
- Location: Makefile:387 (bench-budget), tools/metrics.sh (measure)
- Why: make bench-budget prints the grep scenario's figures and make metrics now measures the same scenario at the same keys, so each check spends the grep runs over 150,000 lines twice.
- Fix: drop the grep line of bench-budget, since make metrics records and compares the figure, and update its help text, the map, and the Makefile's stage notes.
