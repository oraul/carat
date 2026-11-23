# Proposal

## Why

The resume start returned the run state as the free string `state_json`, and the workflow parsed it with `JSON.parse`, its only parse of an agent's text. On 2026-11-23 the start returned the state followed by a closing tag and a parameter fragment, twice on one change; the parse threw, the run failed in 25 seconds each time, and a resume of the failed run replayed the same bad result.

## What Changes

- Change the resume result schema (`RESUME` in `.claude/workflows/deliver-change.js`) so `state` is an object of string values, replacing the string `state_json`: the schema check rejects a malformed answer and the agent answers again before the workflow sees it.
- Add `readResumed` and `leadingObject`: the workflow takes the `state` object, and for a string left over (an older or replayed result under `state_json`) parses only its leading JSON object, dropping appended text, and returns an error, never a throw, for anything not a JSON object naming a change.
- Add `resumeState`: it runs the resume start, and when the state cannot be read starts it once more with a note naming the error; a second failure stops the run with `resume stopped: <error>`. A stopped first result is returned as before, with no second start.
- Add tools-test cases: the 2026-11-23 output reads as the same state, braces and quotes inside strings, unreadable results as errors, the single retry with its note, the stop after two starts, a stopped result with no retry, and the schema and phase wiring.
- Document it in README.md and `docs/codebase-map.md`.

## Impact

- Code: `.claude/workflows/deliver-change.js`.
- Tests: `tools/tools_test.sh`.
- Docs: README.md, `docs/codebase-map.md`.
- docs/architecture.md: unchanged, it does not describe the delivery workflow's resume start.
- CLAUDE.md: unchanged, its Agents text does not describe the resume result.
- No edit of `tools/rules.sh`; the runner agent's guard profile and the run state's writer (`tools/run_state.sh`) are unchanged.
