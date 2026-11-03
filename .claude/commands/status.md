---
description: Show the delivery queue, the running change's phase from its run state, and the last metrics row
allowed-tools: Bash(sh tools/run_state.sh status)
---

Run `sh tools/run_state.sh status` and show its output as it is: the queue (`docs/queue.md`) when it exists, the change whose run state under `build/pipeline/` is not merged with its phases done, its next phase, its stages, reviews, pull request, and CI, and the last row of `docs/metrics.tsv` when it exists. Add nothing else.
