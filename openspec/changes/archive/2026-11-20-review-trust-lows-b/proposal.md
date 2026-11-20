# Proposal

## Why

The open-pr job is the one place `PR_TOKEN` is read, and five security Lows on it stay open:

- "## pr-on-push security Low at tools/open_pr.sh:118": `open_pr.sh wait` takes the number of a pull request whose `refs/pull/N/head` is the pushed commit. Since #166 it refuses several unless one is the number recorded earlier, but git shows no head repository, so a fork's pull request that is the only one on the pushed commit is still recorded, and the merger merges by that number after checking only the head commit.
- "## pr-on-push security Low at .github/workflows/open-pr.yml:39": the token's protection rests on the environment `AI` admitting main alone as a deployment ref, a repository setting nothing checks; without it any branch's own workflow naming the environment reads the token.
- "### Restrict the open-pr edit path to same-repository pull requests (security Low, confidence 4)": `open` lists the open pull requests by head branch name with `gh pr list --head`, which matches a fork's pull request on a branch of the same name, and then edits and reads back by branch name, so a fork's pull request can get pr.md's text instead of ours.
- "### Fork pull requests sharing the branch name block open_pr.sh (security Low (5))": the same count makes a fork's pull request on the branch's name block the open (two open refused) or stand in for ours (one open, so none is created).
- "### open-pr pins its actions by tag beside PR_TOKEN (security Low, confidence 6)": `actions/checkout@v4` is a movable tag running in the job that reads the token.

This is the second part of the queue item `review-trust-lows`, split at b0022b7: Sprint 24 item 1 of `docs/queue-backlog.md`. Outside the roadmap of `docs/architecture.md` section 12: a T1 pipeline defect.

## What Changes

- `tools/open_pr.sh open` lists the branch's open pull requests with their `isCrossRepository` flag and keeps only same-repository ones: none creates the pull request (its number read from `gh pr create`'s output), one is read back and edited by its number, more than one is refused; a fork's pull request on the same branch name is neither counted, edited, nor read.
- A new `tools/open_pr.sh rule` command reads the environment `AI`'s deployment-branch policy with `gh api` and refuses unless it admits exactly one ref, the branch `main`; `open-pr.yml` runs it as the first step after the checkout, with the job's own `GITHUB_TOKEN` (the workflow gains `actions: read`), so the job stops before `PR_TOKEN` is used when the rule is missing or wider.
- `open-pr.yml` pins `actions/checkout` by its full commit sha, the commit the tag `v4` names at this change (v4.4.0), the tag kept in a comment.
- `.claude/agents/merger.md` step 1 reads the pull request's head repository and head branch with its head commit and returns `stale`, not merged, unless they are the input repository and branch, so a fork's pull request the wait recorded is never merged; `open_pr.sh wait`'s comment and usage say so.
- Tests in `tools/tools_test.sh`, one per heading, each failing before its fix: the merger's step requiring the head repository and branch; the rule refused for every branch, a protected-branches policy, an added ref, or a pattern other than main, and passed for main alone; the open step skipping a fork's pull request on the same branch name, creating ours, and editing ours by number beside a fork's; the workflow's step order and token; every action in open-pr.yml pinned by a full sha.
- Docs: README.md delivery step 9 and `docs/codebase-map.md` area 1 (`tools/open_pr.sh`, `open-pr.yml`).

## Capabilities

### New Capabilities

None: the change alters the delivery tooling, no editor behavior (`skip_specs: true`).

### Modified Capabilities

None.

## Out of scope

- No `tools/rules.sh` edit.
- The other workflows (`ci.yml`, `main.yml`, `scan.yml`) keep their actions by tag: none of them holds `PR_TOKEN`; recorded in the change's findings.
- `wait` still refuses several pull requests on the pushed commit at a first push (a fork can delay a delivery); git cannot tell them apart.
- The headings queued as `review-trust-lows-c`, and no file of the feature lane.

## Impact

- README.md: changed, delivery step 9.
- CLAUDE.md: changed, the Commands line of `tools/open_pr.sh` names the workflow's new `rule` command.
- docs/architecture.md: unchanged, section 10 does not describe the open-pr job.
- docs/codebase-map.md: changed, area 1's `tools/open_pr.sh` and `open-pr.yml` entries.
- docs/compatibility.md, docs/actions.md: unchanged, no Neovim command and no action.
