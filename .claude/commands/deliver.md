---
description: Deliver one change to main through the delivery workflow, or resume it from its run state
argument-hint: <change name or brief>
---

Deliver this change through the delivery workflow: $ARGUMENTS

1. If the argument names a change under `openspec/changes/` or a run state `build/pipeline/<name>.json`, pass it as `change`; otherwise pass the whole argument as `brief`. Scout packs or an assigned branch named in the argument go in `packs` and `branch`.
2. Run the Workflow tool with `scriptPath` `.claude/workflows/deliver-change.js` and those `args`. The workflow reads the run state on start, so running it again after an interruption resumes at the first phase not done at the current commit.
3. When it returns, show its report as it is. Do not implement, check, review, push, or merge anything yourself: every phase belongs to the workflow's agents.
