# Proposal

## Why

The delivery workflow does not hold every start to the brief. The Resume start's prompt is built from the whole workflow input (`JSON.stringify(input)`), so any field a session passes beside the brief, such as the user's latest chat message, reaches an agent as if it were part of the request; and the package start, the one that pushes, gets only the backlog handover and the planner's instruction, never the brief. A brief that said to hold for the user's reading before the push therefore never reached the start that pushed, and #137 pushed and merged before the user read it. Separately, docs-lint refuses a sprint of more than one pipeline item even when the user approved the exception, and its usage header says a sprint holds 1 to 5 items while the check allows 0 to 5 (a drained sprint).

## What Changes

- The workflow keeps only its known arguments (`change`, `brief`, `branch`, `packs`, `areas`, `records`) from what it is started with; any other field is dropped before a start's prompt is built, so a start's prompt carries the brief or the resume brief only.
- Every contributor start, implement, fix, package, wait, push, and body alike, carries the brief (the request, or the resume brief naming the queue item), so an instruction in it, a hold for the user included, reaches the start that pushes.
- The resume brief, the brief of a change started by its name, names the queue plan-needed read: build/plan/queue.md only while a sprint plan waits there, docs/queue.md otherwise, never both with the plan line pasted in.
- docs-lint honors a user-approved exception: a line beginning `The user-approved exception` under a `## Sprint` heading, before the next `## ` heading, lifts that sprint's limit of one pipeline item. The limit of 0 to 5 items stays. The usage header says 0 to 5 items and names the marker.
- Cases in `tools/tools_test.sh` prove each of the above.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None: the change alters the delivery pipeline and a documentation check, which no spec under `openspec/specs/` describes (`skip_specs: true`).

## Impact

- `.claude/workflows/deliver-change.js`: the argument filter, the brief in every contributor start, and the resume brief.
- `tools/docs_lint.sh`: the exception marker and the header.
- `tools/tools_test.sh`: the workflow and docs-lint cases.
- `docs/codebase-map.md`: area 1's `tools/docs_lint.sh` line names the marker.
- CLAUDE.md: changed, the Agents section says every contributor start carries the brief and the sprint rule names the marker.
- README.md: unchanged, no command, binding, option, or user-visible editor behavior changes.
- docs/architecture.md: unchanged, no layer, port, or roadmap item changes.

Outside the roadmap of `docs/architecture.md` section 12: a pipeline fix (T1) the user approved as sprint 8's first item.

Backlog headings this change covers, from its queue entry: "### docs_lint's usage header says a sprint holds 1 to 5 items" and "### Delivery brief names the sprint queue even when none waits (`sprint-planning` quality advisory)".

## Out of scope

- Reordering the queue, or any other item of sprint 8.
- Applying build/plan/ to docs/queue.md: the package step does that, and the plan's Sprint 8 line already begins with the marker this change honors.
- Lifting the five-item limit of a sprint, or checking the three-feature, two-fix mix, which docs-lint does not check.
- The `/deliver` command text: the workflow's filter makes any extra field harmless whatever the session passes.

Assumptions recorded here instead of asked: no code at `.claude/workflows/deliver-change.js:945` relays a chat message by name; the path by which a field beside the brief reaches a start is the Resume start's `JSON.stringify(input)`, so the fix filters the input to the known arguments. The planner, scouts, and reviewers keep their prompts as they are: the planner and scouts already carry the brief, and the checker, reviewers, benchmark, merger, and close starts carry no user text at all. The marker lifts only the pipeline limit, since the brief's acceptance asks for a marked sprint of 4 pipeline items within the five-item sprint.
