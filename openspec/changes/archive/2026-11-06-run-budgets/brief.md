# Brief

run-budgets: docs/queue.md item 1 as the planner wrote it (T1 user request, estimated medium, pushed back 5). The user asked for this one now; after it the queue holds again until the user says go. No planner decision is needed. Security review is never skipped.

Plan notes:

- Add the build/plan/backlog.md entry 'Pull requests are created with a session-link footer the settings turn off' to docs/backlog.md. It holds the locations for queue item 7 pr-footer: step 4 and step 5 of the package step in .claude/agents/contributor.md, and the attribution block in .claude/settings.json.
- Update the evidence of the docs/backlog.md entry 'A refused backup push is retried and protects nothing here' (line 851): add leader-layout's 2 of 2 refused backup tries (retro note 8). The user may want to revisit the earlier decision to keep this in the backlog, since no backup has reached origin in four runs.
- No action needed for the old build/plan/backlog.md entries from the leader-layout plan (41 UI groups, StatusLineNC). They are already in docs/backlog.md at lines 1271 and 1277, and the file has been rewritten with the new entry.
- The leader-layout quality advisories (notes 1 to 5) are already in docs/backlog.md from line 1243 on. They are now queued as item 42 and need no backlog edit.
- build/plan/queue.md is 17,311 bytes, under the docs/queue.md budget of 17,369 in tools/docs_lint.sh. Every item names a tier and a size.
