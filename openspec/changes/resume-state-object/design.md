# Design

## Context

`trusted` prints the run state as one flat JSON object of string values. The resume start relayed it verbatim as a string and the workflow parsed it; any text the agent added after it broke the parse.

## Goals / Non-Goals

**Goals:**
- The result schema carries the state as an object, so the existing result check, not the workflow, rejects a malformed answer.
- An unreadable state costs one more start with a note, then a stop with the error.

**Non-Goals:**
- Other starts' results, which are already schema-checked objects.
- The run state's writer, `tools/rules.sh`, or the runner's guard profile.

## Decisions

- `state` is `type: object` with string `additionalProperties`, matching what `write_key` writes, and required in place of `state_json`.
- `readResumed` still accepts a string, from the `state_json` of a replayed result, taking its leading balanced object (quotes and escapes respected) so appended text is dropped. It validates a change name, since `CHANGE` is tested later and a state with none would be refused there with a less useful message.
- `resumeState(start)` takes the agent call as a function so tools-test runs it with stubs; the second start gets a distinct label and the note as its prompt tail.

## Risks / Trade-offs

- The second start costs one runner start; it runs only when the first answer is unreadable.
