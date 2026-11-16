### The contributor's list of the other agents' phases drops the benchmark
- Location: .claude/agents/contributor.md:14
- Why: the benchmark still runs as its own phase, so the list misleads a reader of the agent; the fix did not fit the file's budget without a trim after the reviews
- Fix: restore benchmark to the list, trimming six bytes elsewhere in the file

