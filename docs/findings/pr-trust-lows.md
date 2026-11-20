
### A concurrent lane's benchmark log fails another lane's check (pr-trust-lows check)
- Location: tools/run_state.sh tree_scan and main_scan; .claude/agents/benchmark.md step 1
- Why: the check of pr-trust-lows refused every pass because the main checkout's build/base-build.log changed while it ran; the feature lane's benchmark agent wrote that log while building origin/main in tmp/.base, so one lane's benchmark voids the other lane's check and costs a fix round with no defect in the change.
- Fix: have the benchmark agent write its base build log under tmp/.base (or name the log path in benchmark.md step 1 and let the guard refuse other build/ paths of the main checkout), or prune a named benchmark log directory in tree_scan as the stage logs are, with a tools-test case that a write there during a lane's check is not reported.
