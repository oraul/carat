fix(merger): squash-merge with the pr.md body, its sections kept

## Summary

The merger now squash-merges with a message printed by `tools/open_pr.sh message`, which is the archived pr.md body byte for byte plus the co-author trailer, so main's commit body keeps the four sections and their dividers. The squash commits of #234 and #236 kept only a summary paragraph because the merger wrote its own message instead of copying the pull request body, which breaks the CLAUDE.md rule that the description is the squash body.

---

## Changes

- Add `tools/open_pr.sh message CHANGE SHA`, which prints the body of the change's one archived pr.md at SHA, one blank line, and the trailer, and refuses a bad change name or sha, a sha with no single archived pr.md of the change, and an empty body
- Change step 5 of the merger agent to one `open_pr.sh message` call in the main checkout, its output passed exactly as the commit message and the pushed head as `expectedHeadSha`, so the first green costs eight calls instead of nine
- Fix the merge tool guard in `tools/agent_guard.sh` to read the expected head from `expectedHeadSha`, the tool's real parameter, and refuse a call without it
- Allow the merger to run `open_pr.sh message` in the guard, refuse it after a cd into a worktree in the same call so the branch's copy never runs, clear that worktree on a cd back to the project, and keep it refused for the contributor
- Add tools-test cases for the message built from a four-section pr.md with its headings, dividers, and trailer kept, its refusals including two archived pr.md, and the guard's new allowances and refusals
- Document the `message` command in CLAUDE.md Commands, README.md, the code map, and the headers of both scripts, and record the finding on the agents' hooks in the change's findings file

---

## Testing

- Run the security review on the committed diff at a7a7bc8, pass with no High, Medium, or Low finding
- Run the quality review at a7a7bc8, pass with no blocking finding and no open advisory
- Run the checker's stages at a7a7bc8 (gates, docs-lint, dev-build, test-build, test-run, tools-test, diagnose, bench-budget, metrics), all pass
- Run the benchmark review at a7a7bc8, pass
- Run make spec-validate after the archive, 54 passed and 0 failed

---

## Notes

The post-merge check that reads main's new commit body and records a defect note when a section heading is missing is left out of this change and queued as the backlog item merge-body-check. Why the agents' frontmatter hooks did not judge the earlier merge calls lies outside the repository and is recorded as a finding. No change to `tools/rules.sh`.
