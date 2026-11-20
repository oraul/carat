
### A concurrent lane's benchmark log fails another lane's check (pr-trust-lows check)
- Location: tools/run_state.sh tree_scan and main_scan; .claude/agents/benchmark.md step 1
- Why: the check of pr-trust-lows refused every pass because the main checkout's build/base-build.log changed while it ran; the feature lane's benchmark agent wrote that log while building origin/main in tmp/.base, so one lane's benchmark voids the other lane's check and costs a fix round with no defect in the change.
- Fix: have the benchmark agent write its base build log under tmp/.base (or name the log path in benchmark.md step 1 and let the guard refuse other build/ paths of the main checkout), or prune a named benchmark log directory in tree_scan as the stage logs are, with a tools-test case that a write there during a lane's check is not reported.

### The OpenSpec pin leaves its transitive dependencies unpinned (`pr-trust-lows` security Low (5), three passes, and quality advisory)
- Location: Makefile:139 and :140 (`OPENSPEC_PACKAGE`), tools/spec_validate.sh:18, tools/agent_guard.sh:902; the design's residual-risk sentence (archived design.md:11, tasks.md:22).
- Why: pinning `@fission-ai/openspec@2.1.1` fixes only the top-level package; with no lockfile, npx resolves the package's dependency ranges afresh on a cold cache, so a hijacked dependency of OpenSpec could still run code in the contributor or checker session that holds the push credentials. Reported at d388c4a, again at ee4ce6c (which added CLAUDE.md as a fourth place the pin must match, no lockfile), and at d005798 (which only reworded the design to say the risk is recorded for a later change); this entry is that record.
- Fix: commit a package.json and a package-lock.json with integrity hashes for OpenSpec under tools/, install it with `npm ci --ignore-scripts`, and run the installed binary instead of npx in the Makefile, tools/spec_validate.sh, the guard's allowlist, and CLAUDE.md's OpenSpec line, keeping the tools-test pin comparison over the new form.

### The contributor guard still admits the bare openspec command outside the pin (`pr-trust-lows` security Low (3), two passes)
- Location: tools/agent_guard.sh:896 and :902, `judge`, the contributor's OpenSpec cases.
- Why: the bare `openspec` command resolves through PATH to whatever installation exists, so the version pin does not cover that path; it predates the change, and the design keeps it on purpose as an installation the user made.
- Fix: either check in the guard, or in a wrapper, that the PATH `openspec` reports the pinned version, or limit the contributor to the pinned npx (or vendored binary) form, with a tools-test case for the refusal.
