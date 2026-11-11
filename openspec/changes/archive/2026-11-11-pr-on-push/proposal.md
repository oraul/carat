# Proposal

## Why

A pull request created or edited over GitHub's API from a cloud session reaches GitHub with a footer the cloud network layer appends, and this session's git proxy allows pushing a branch but refuses a tag push and a remote ref delete, so the tag trigger of `pr-by-tag` (archived on this branch, never merged) cannot run. This change delivers decision 19 of `tmp/briefs/pipeline-skeptic.md` (the user's decision of 2026-11-11): GitHub Actions opens the pull request on the push of the change branch itself. It replaces `pr-by-tag` and `publish-pr` (PR 105, closed). It is outside the roadmap of `docs/architecture.md` section 12: it is delivery process.

## What Changes

- The package step writes the gated title and body into the archived OpenSpec change as `pr.md` (the title line, a blank line, the body: `sh tools/open_pr.sh write CHANGE TITLE`, which gates both first), commits it, and pushes the branch once; git carries the text clean and it stays as the change's record.
- `.github/workflows/branch-push.yml` (replacing `pr-tag.yml`), on a push of a `feature/`, `bugfix/`, `hotfix/`, `release/`, or `chore/` branch, holds no permissions, checks out nothing, and runs no repository code.
- `.github/workflows/open-pr.yml` runs as branch-push's `workflow_run`, so always from main: it checks out main only, reads the branch's one new `pr.md` as data with main's `tools/open_pr.sh read`, runs main's `tools/gates.sh pr-body` and `tools/scan_text.sh` on it, and, in the job declaring `environment: AI` with that environment's `PR_TOKEN` (never `GITHUB_TOKEN`), opens the pull request with `gh pr create`, reads it back, and fails unless title and body match. It does nothing when the branch has no new `pr.md`, is gone, or already has an open pull request. No step pushes a tag or deletes a ref; its delete job goes.
- The contributor waits for its branch's pull request (`sh tools/open_pr.sh wait CHANGE`), records its number, and the delivery continues to CI and the merger's squash-merge; a package step returning no number stops the run. A pull request already open before the push (opened by hand, which open-pr leaves alone) gets the title and the body file through the session's update tool, an edit, which arrives clean.
- `tools/pr_tag.sh` and its tools-test cases are replaced by `tools/open_pr.sh` and the `pr.md` cases; the guard lets the contributor run only `write` and `wait`, and its one push is again `tools/run_state.sh push`.
- Kept from the branch: the split of the trigger from the job holding the token, the guard's contributor form, the agents' and workflow's tests, and the check clone's `CARAT_BIN=build/dev/carat`.

Out of scope: the merger and CI; the body mode (its update tool already arrives clean); `sprint-planning` and `ci-time`; the archived `pr-by-tag` change, which stays as the record of the tag design that was replaced; the repository settings the user applies by hand (the environment `AI` allowing main alone, its secret `PR_TOKEN`).

Assumptions:

- `pr.md` lives at `openspec/changes/archive/DATE-CHANGE/pr.md`; open-pr takes the one such file in the branch tip's tree that main's tree lacks, so an older change's record on main is never reopened, and refuses more than one.
- Title and body are compared after removing trailing newlines, since `gh` prints each with one newline of its own; every other byte must match.
- For this bootstrap, pull request 108, opened by hand, gets its title and body through the update tool at the package step, as the general already-open rule above says; open-pr runs only once it is on main.

## Capabilities

### New Capabilities

None: the change is delivery process and alters no editor behavior (`skip_specs: true`).

### Modified Capabilities

None.

## Impact

- `tools/open_pr.sh` (new), `tools/pr_tag.sh` (removed), `.github/workflows/branch-push.yml` (new), `.github/workflows/pr-tag.yml` (removed), `.github/workflows/open-pr.yml`, `tools/agent_guard.sh`, `tools/tools_test.sh`, `.claude/workflows/deliver-change.js`, `.claude/agents/contributor.md`, `docs/codebase-map.md`.
- CLAUDE.md: changed, the contributor's pull request path and the `tools/open_pr.sh` command.
- README.md: changed, the package step and the guard's pushes.
- docs/architecture.md: unchanged, section 10 names no pull request creation path.
