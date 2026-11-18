
### The check starts gates before test-build has written the test runner
- Location: tools/run_state.sh, STAGE_AFTER (the stage order of check-run)
- Why: the snapshots gate of tools/gates.sh runs build/test/run_all whenever a commit changes a test/*.expected, but STAGE_AFTER has no gates:test-build pair, so when the carried stages leave the queue short, gates starts as soon as docs-lint ends (about 27 s) while test-build still compiles (about 150 s), fails with "build/test/run_all is missing", and the check kills test-build; it failed this way at 118500e1d053 although make test-build then make gates pass in the lane.
- Fix: add gates:test-build to STAGE_AFTER, with a tools-test case that a check whose head changes a snapshot starts gates only after test-build passed.
