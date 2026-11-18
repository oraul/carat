fix(merger): hold the squash message to pr.md's body

## Summary

The merge hook now refuses a squash merge whose message is not exactly the body of the archived change's pr.md at the pushed head followed by the trailer, and the merger reads that body from pr.md and passes it whole. Since #199 most squash commits on main carried a one-sentence body instead of the four sections, because the message was the merger's own tool argument and nothing compared it with pr.md, so the history on main lost each change's Summary, Changes, Testing, and Notes.

---

## Changes

- Add a squash message check to the merge hook in tools/agent_guard.sh that decodes the message's JSON string whole, compares it byte for byte with pr.md's body at the pushed head, one blank line, and the trailer, and refuses naming the first differing line or a missing message.
- Refuse a merge when the pushed head holds no archived pr.md of the change or more than one, or when the run state is not named after a change, and fail closed when the comparison does not run.
- Change the merger's steps 5 and 6 in .claude/agents/merger.md to list the archive's entries without recursion, print pr.md's body at the pushed head, pass it unshortened, and confirm the body after the merge.
- Add tools-test cases that pass the exact message, including escaped and raw text outside ASCII and a tab, and refuse a missing, shortened, trailer-less, altered, or over-long message, a head without or with two archived pr.md files, and a run state not named after a change.
- Add a tools-test case that keeps the hook's squash trailer equal to the trailer of tools/gates.sh, and a case that keeps the merger's first green within its call cap.
- Document the hook's squash message check in README.md pipeline step 9 and in the tools/agent_guard.sh entry of docs/codebase-map.md.
- Record the three remaining quality advisories in docs/findings/squash-body-full.md, and the backlog lane's plan and metrics history.

---

## Testing

- Run the security review of the committed diff at 0adec3d, pass with no High, Medium, or Low finding.
- Run the quality review at 0adec3d, pass with no blocking finding and two advisories, recorded in the findings file.
- Run the checker's stages at 0adec3d (docs-lint, dev-build, test-build, diagnose, test-run, gates, bench-budget, tools-test, metrics), all pass.
- Run make spec-validate after archiving, 54 of 54 items pass.

---

## Notes

The hook that judges this pull request's own merge is main's, which has no squash message check yet, so this squash commit may still carry a short body; the next delivery's squash commit is the acceptance check that all four sections reach main. The check lives in the pre-merge hook rather than a post-merge check because a squash commit on main cannot be undone without rewriting main, while a refusal lets the merger retry in the same start. tools/rules.sh and .claude/workflows/deliver-change.js are not edited, since the workflow builds no merge message.
