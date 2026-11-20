fix(tools): keep the open-pr job to same-repository pull requests

## Summary

Hardens the open-pr job, the one job that reads PR_TOKEN, so a fork's pull request on the same branch name is never counted, edited, read back, or merged, the job stops unless the environment AI admits the branch main alone, and its checkout action is pinned by commit. Five security Lows on that job stayed open after the first part of the queue item, review-trust-lows, and each let a fork or a moved tag reach the token's work.

---

## Changes

- Change `tools/open_pr.sh open` to list the branch's open pull requests with their cross-repository flag and keep only same-repository ones, creating ours when none is left, editing and reading back the one left by its number, and refusing more than one.
- Add a `tools/open_pr.sh rule` command that reads the environment AI's deployment-branch policy and refuses unless it admits exactly one ref, the branch main, run in `open-pr.yml` right after the checkout with the job's own token and `actions: read`, before PR_TOKEN is used.
- Pin `actions/checkout` in `open-pr.yml` by its full commit sha, the tag v4.4.0 kept in a comment.
- Change the merger's step 1 to read the pull request's head repository and head branch with its head commit and return stale unless they are the input's, so a fork's pull request the wait recorded is never merged, and say so in the comment and usage of `open_pr.sh wait`.
- Add tests in `tools/tools_test.sh`, one per security heading, each failing before its fix: the merger's head repository and branch check, the rule refused for wider or missing policies and passed for main alone, the open step skipping a fork's pull request and editing ours by number, the workflow's step order and token, and every open-pr action pinned by a full sha.
- Name `rule` beside `read`, `gate`, and `open` in the `tools/agent_guard.sh` comment as the open-pr workflow's alone, refused to every agent profile like them.
- Document the change in README.md delivery step 9, the `tools/open_pr.sh` Commands line of CLAUDE.md, and area 1 of `docs/codebase-map.md`.
- Record the plan's backlog entries in the change's findings file, the next backlog queue, and the metrics history row of the first part.

---

## Testing

- Run the security review of the committed diff, pass with no High, Medium, or Low finding.
- Run the quality review, pass with no blocking finding, its advisories closed in place.
- Run the checker's stages (dev-build, test-build, diagnose, test-run, gates, docs-lint, bench-budget, tools-test, metrics), all pass.
- Run the benchmark review, pass with no allocation or round change.
- Run `make spec-validate` after the archive, all 55 items pass.

---

## Notes

This is part b of the queue item review-trust-lows, split at b0022b7; it does not edit `tools/rules.sh`. The other workflows keep their actions by tag since none holds PR_TOKEN, recorded in the change's findings file, and `open_pr.sh wait` still refuses several pull requests on the pushed commit at a first push, because git cannot tell their head repositories apart. The rule step depends on the repository setting that limits the environment AI to main, so a run stops at that step until the setting admits main alone.
