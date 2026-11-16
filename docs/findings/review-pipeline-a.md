
### The merger's checks list has no stated source for each check's workflow
- Location: .claude/agents/merger.md:24 (step 2)
- Why: the merger is told to return every check as workflow, name, status, conclusion but to read the workflow files only when a check failed, and never how a check run is matched to its workflow run, so a tier that omits the field turns each stale red into a needless fix round, since staleRed treats an entry without a workflow file as not stale.
- Fix: say the workflow field is needed only on red, and match each check run to the workflow run of its check suite id.
