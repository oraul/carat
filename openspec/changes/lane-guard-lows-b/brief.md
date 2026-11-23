# Brief

CHANGE: lane-guard-lows-b   LANE: backlog   BRANCH: bugfix/lane-guard-lows-b   BASE: 6f0ecc34bd9d
WHERE: `tools/open_pr.sh:183` (wait calls head_owned), `tools/open_pr.sh:108` (head_owned reads the pull request back with gh); `.claude/agents/merger.md:23` (step 1 already compares the pull request's head repository and head branch with the input's before any merge).
WHY: since #328, wait records a pull request only after gh reads it back, and gh cannot run in this delivery environment on any route, so every delivery stops at wait and none can merge; the merger's step 1 already holds the GitHub read tool and refuses a pull request whose head repository or branch differs.
OUTCOME: wait records the lone matching pull request without gh again (head_owned and its call removed, the header lines naming it updated), and the head-repository guard of checks-and-pr-lows security Low (3) is kept by the merger's step 1, which the header of tools/open_pr.sh names as the place the head is confirmed.
ACCEPTED WHEN: a tools-test case where gh is absent from the PATH and one pull request has the pushed head fails before (wait refuses) and passes after (wait records it); the head_owned tests are removed with it.
CONSTRAINTS: only the repository rules that apply; none added
OUT OF SCOPE: anything not named in OUTCOME; recordNotes in sprint-planning.js, the package step's prose-only edit, the budget line, and the control characters stay for lane-guard-lows-c
USER DECISIONS: the user (2026-11-23): gh cannot run here on any route, so take the wait head-repository check out of wait and let the merger, which holds the GitHub read tool, confirm the pull request's head repository before merging.
RULES: no agent reads, greps, or opens docs/backlog/ or docs/findings/*.md; a finding this change does not fix is appended to docs/findings/lane-guard-lows-b.md, none dropped; the pull request is opened by the branch-push Action from pr.md; no URL, address, or model name anywhere; keep to exactly this and name anything extra.
