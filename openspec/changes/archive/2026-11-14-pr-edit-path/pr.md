chore(pipeline): open and edit pull requests only from pr.md

## Summary

Every pull request title and body now reaches GitHub from the branch's committed pr.md on a push, with open-pr setting an open pull request's text to it, and no session holds a GitHub pull request tool any more. The body mode edited the pull request with a session tool that gets a footer appended, the README contradicted the scripts, and a resumed run that had pushed without a recorded pull request number reran the package step into a refused second push.

---

## Changes

- Change open-pr to set an open pull request's title and body to pr.md when they differ, reading them back equal, and to refuse a branch with more than one open pull request
- Change the body mode to rewrite pr.md, commit it, and push it as a CI fix, with the workflow keeping the recorded sha for the merger
- Remove the GitHub pull request tools from the contributor's grant and match every mcp tool in its guard hook
- Add a contributor wait mode that a resume with a recorded push but no pull request number runs instead of the package step
- Document the one pull request rule in tools/open_pr.sh, the open-pr workflow, the contributor agent, CLAUDE.md, the README, and the code map
- Cut the contributor agent under 7,000 bytes, a budget tools/docs_lint.sh keeps, with tools tests for the edit path and the budget
- Record the planner's queue, the metrics row of the last merged change, and the review findings in the backlog

---

## Testing

- Run the security review of the committed diff, pass with no High or Medium finding; one Low finding at confidence 4, the edit path matching a fork's pull request by branch name, is recorded in the backlog
- Run the quality review, pass with no blocking finding and four advisories recorded in the backlog
- Run the benchmark comparison against main's recorded figures, pass
- Run the fast check stages docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, metrics, tools-test, and gates, all pass
- Run make spec-validate after archiving, 51 passed and 0 failed

---

## Notes

A push now resets an open pull request's text that someone edited on GitHub back to pr.md's, since pr.md is the one source of the squash body. After a body push the scan runs once on the synchronize event with the old text and again after open-pr's edit; the merger keeps only the latest run of each check. Restricting the edit path to same-repository pull requests is left as a backlog item.
