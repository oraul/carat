---
description: Ask the planner for the next order of the queue, with the data behind each decision; changes nothing tracked
argument-hint: [question about the queue]
---

Plan the queue: $ARGUMENTS

1. Start the `planner` agent with the Agent tool. Its input: "Mode: /plan. Question: <the argument, or 'the next order of docs/queue.md'>". It reads the metrics history, the pending run states, and the goals (never the backlog), and writes its proposal under `build/plan/`.
2. Show its decisions as it returns them, each with its evidence, then any blocking security finding it puts first, then the paths it wrote.
3. Do not edit `docs/queue.md`, `docs/goals.md`, or anything else: the queue changes only through a delivery, whose Plan phase runs the planner again on the newest data and whose package step commits the result. To act on the plan, run `/deliver` with the change at the head of the queue.
