### periodic-review.js's record start still runs unguarded on the session's model

- Location: `.claude/workflows/periodic-review.js`, the record start (`RECORD_CAP`), started with no `agentType`.
- Why: it runs one workflow-written `tools/run_state.sh review` line like the delivery's record start, which `cheap-tier` moved to the guarded runner on the cheapest tier; this one still costs the session's model and has no hook.
- Fix: start it with `agentType: 'runner'` at low effort and add a tools-test case, once its keep rule over the next 5 rows holds for the delivery and sprint starts.
