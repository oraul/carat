chore(tools): open the pull request on the change branch push

## Summary

Opens a delivery's pull request from GitHub Actions when its change branch is pushed, using a title and body committed as pr.md in the archived OpenSpec change. A pull request created from a cloud session gets a footer appended by its network layer, and its git proxy refuses tag pushes and ref deletes, so neither the session's create tool nor the tag trigger of pr-by-tag can open a clean pull request. The workflow that holds the token runs from main only and reads the branch's pr.md as data, gated by main's scanners.

---

## Changes

- Add tools/open_pr.sh, whose write mode gates the title and body and writes pr.md into the archived change, whose wait mode records the number of the pull request at the pushed head, and whose read, gate, and open modes serve the workflow.
- Add .github/workflows/branch-push.yml, a trigger on pushes of the allowed branch types with no permissions, no checkout, and no repository code.
- Add .github/workflows/open-pr.yml, run from main after branch-push, which reads the one new pr.md, gates it with main's tools, opens the pull request with the AI environment's PR_TOKEN, and fails unless the read-back title and body match.
- Change the contributor's package step and the delivery workflow so the contributor commits pr.md, pushes once, waits in the foreground for the pull request, and never calls a pull request create tool; a step returning no number stops the run.
- Change tools/agent_guard.sh so the contributor may run only the write and wait modes of open_pr.sh, and replace the pr_tag.sh cases in tools/tools_test.sh with open_pr.sh and guard cases.
- Archive the pr-by-tag change as the record of the replaced tag design and the pr-on-push change with its brief, proposal, design, and tasks.
- Document the pull request path in CLAUDE.md, README.md, the Makefile help, and docs/codebase-map.md.
- Record the planner's queue and append the review findings and the planner's backlog entries to docs/backlog.md.

---

## Testing

- Run the security review of the committed diff at a2d4b6c, pass with no High or Medium finding; two Low findings (the wait step trusting any pull request at the pushed sha, and PR_TOKEN depending on the AI environment's deployment-branch rule) are recorded in docs/backlog.md.
- Run the checker's stages at a2d4b6c (docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, metrics, tools-test, gates), all pass.
- Run the quality review at a2d4b6c, pass with no blocking finding after one fix round; its advisories are recorded in docs/backlog.md.
- Run the benchmark comparison at a2d4b6c, pass with no regression.
- Run make spec-validate, make gates, and make docs-lint after archiving, all pass.

---

## Notes

This pull request was opened by hand before the push, so open-pr leaves it alone and its title and body are set through the update tool; open-pr runs for later deliveries once it is on main. The user applies by hand the repository settings the workflow needs: the AI environment allowing only main as its deployment branch, and its PR_TOKEN secret, ideally a fine-grained token scoped to this repository. The quality advisories on open_pr.sh (the WAIT_STEP bound, branch names with dots, the read-back by branch name, the wait deadline) are left for a follow-up.
