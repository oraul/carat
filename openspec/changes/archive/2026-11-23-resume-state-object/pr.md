fix(workflow): read the resume start's run state as an object

## Summary

The delivery workflow now reads the resume start's run state as a structured object in the result schema instead of parsing a free string. On 2026-11-23 the resume start returned the state followed by a closing tag and a parameter fragment, so the workflow's JSON parse threw twice and the run failed in 25 seconds each time. The schema check now rejects a malformed answer so the agent answers again, and an unreadable result is retried once before the run stops.

---

## Changes

- Change the resume result schema so the state is an object of string values, replacing the string state_json, in the deliver-change workflow
- Add readResumed and leadingObject, which take the state object, parse only the leading JSON object of a leftover string, and return an error instead of throwing on anything unreadable
- Add resumeState, which starts the resume once more with a note naming the error when the state cannot be read, and stops with the error after a second failure
- Add tools-test cases for the 2026-11-23 output, braces and quotes inside strings, unreadable results, the single retry with its note, the stop after two starts, a stopped result, and the schema and phase wiring
- Document the change in README.md and docs/codebase-map.md

---

## Testing

- Run the security review of the committed diff, pass with no High, Medium, or Low findings
- Run the benchmark review, pass with no blocking findings
- Run the fast stages through the run state check at the implementation head (docs-lint, dev-build, test-build, diagnose, bench-budget, tools-test, test-run, gates, metrics), all pass
- Run make spec-validate after archiving, 56 of 56 pass

---

## Notes

None
