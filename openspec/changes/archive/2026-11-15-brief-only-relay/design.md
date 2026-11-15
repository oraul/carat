# Design

## Context

`.claude/workflows/deliver-change.js` builds each agent start's prompt. `input` was the raw `args`, which the Resume start stringified whole; the brief (`brief`, the request or the resume brief naming the queue item) reached the scouts and the implement start but no other contributor start. `tools/docs_lint.sh` `check_queue` counts the pipeline items of the `## Sprint` section and fails above one.

## Goals / Non-Goals

Goals: a start's prompt holds the brief or the resume brief and no other relayed text; every contributor start holds the brief; docs-lint passes a sprint the user approved with more pipeline items.

Non-goals: changing what the checker, reviewers, merger, or close starts read; the five-item limit.

## Decisions

### The input keeps the known arguments only

`ARG_KEYS` lists the arguments the header documents; `startInput(args)` returns a string argument as `{ brief }` and an object with only those keys. `input` is `startInput(args)`, so the Resume start's `JSON.stringify(input)` and every later use see nothing else. Dropping rather than refusing an unknown field keeps a resume working when a session passes extra text.

### The brief is in the contributor's task line

`contributorTask(mode, brief, detail)` returns `Mode: <mode>. Brief: <brief>. <detail>` and `contributor()` builds every start from it, so implement, fix, package, wait, push, and body all carry it, and the implement detail no longer repeats it. A pure function lets `tools/tools_test.sh` run it under node for every mode with a brief holding a hold-for-the-user instruction. The brief reaches the package start as data like any other brief line; the contributor's Mandate already stops on what the brief asks.

### The resume brief names one queue

`resumeBrief(change, planLine)` names build/plan/queue.md when the plan line (plan-needed's, which names the queue it read) does, docs/queue.md when it names that, and both, as before, only when it names neither (a pending change's proposal made the plan needed). This is the quality advisory "Delivery brief names the sprint queue even when none waits".

### The exception marker

A line beginning `The user-approved exception` inside the sprint section (from the `## Sprint` heading to the next `## ` heading) lifts the pipeline limit for that sprint. A line start, not a substring, so an item's parenthesis naming the exception (an item line starts with its number) does not count, and the planner's Sprint 8 line already has the form. The 0-to-5 count still applies.

## Risks / Trade-offs

- A marker is text anyone editing the queue can add: the queue is written only by the planner and applied by the package step, and the pull request diff shows the line, so the risk is the same as editing the check.
- A longer prompt for the wait, push, and body starts: one brief, a few hundred bytes.
