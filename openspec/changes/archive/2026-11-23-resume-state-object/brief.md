# Brief

CHANGE: resume-state-object   LANE: backlog   BRANCH: bugfix/resume-state-object
WHERE: .claude/workflows/deliver-change.js:234 (RESUME schema: state_json is a free string, "the output of tools/run_state.sh trusted, verbatim"); :1647 (`state = JSON.parse(resume.state_json)`, the workflow's only parse of an agent's text); the resume start just above it (phase('Resume'), the runner agent on the cheapest tier).
WHY: on 2026-11-23 the resume start returned state_json as the run state followed by `</state_json>` and a `<parameter name="reason">` fragment, twice on one change (wf_bdb5fc46-cf8, wf_d907fb47-c57); JSON.parse threw and the run failed in 25 seconds each time, and a resume of the failed run replays the same bad result.
OUTCOME: the resume result carries the run state as a structured JSON object in its schema (not a string the workflow parses), so the result check rejects a malformed answer and the agent answers again before the workflow sees it; if the state still cannot be read, the workflow starts the resume once more with a note and stops only on a second failure.
ACCEPTED WHEN: a tools-test case feeds the 2026-11-23 malformed output and the run continues with the same state, and an unreadable result is retried once then stopped with its error; both fail before the change; make gates passes.
CONSTRAINTS: no model name or alias anywhere in names or prose; an edit of tools/rules.sh stops the run and is named; the run state stays written only by tools/run_state.sh; the runner agent's guard profile is unchanged.
OUT OF SCOPE: other starts' results (already schema-checked objects); the feature lane's files (docs/queue-feature.md, docs/metrics-feature.tsv).
USER DECISIONS: "show me a solution for this to not happen so we add to sprint", "Go" (2026-11-23): first in the backlog lane right after bench-skip-nonruby, by the user's exception; delivered through the pipeline, no hand edit.
