# Backlog: .github/workflows/open-pr.yml

## pr-by-tag quality advisory at .github/workflows/open-pr.yml:40

- Where: `.github/workflows/open-pr.yml:40`. Delivery review of `pr-by-tag` (quality advisory) at 742ba5f.
- Why it matters: the comment says a branch cannot weaken the checks of its own title and body, but the workflow file and the tools/pr_tag.sh that calls main's gates are the tagged commit's, so a branch can skip them.
- Fix outline: reword it to say main's gates sit beside the scan workflow's base-commit scanner, as design.md Risks already admits.
- Category: pipeline
- Added: 2026-11-11

### Actions pinned to mutable tags beside a token

- Location: .github/workflows/open-pr.yml:45, ci.yml, main.yml (sprint-8 sweep, security Low (5)); queued in `ci-hardening`.
- Why: actions/checkout is pinned to the v4 tag in the job that later reads PR_TOKEN.
- Fix: pin every action to a full commit hash.
- Category: security
- Added: 2026-11-16

### Workflow actions are pinned by movable tags

- Location: .github/workflows/open-pr.yml:48 and every workflow (sweep, security Low (5)).
- Why: actions/checkout and actions/cache are pinned by the tag v4, here in the job of environment AI that holds PR_TOKEN.
- Fix outline: pin every action to a full commit hash.
- Category: security
- Added: 2026-11-17

### Actions/checkout is pinned by the mutable tag v4 in the job that holds (sprint-20 sweep security Low (4), open-pr.yml:46)

- Location: `.github/workflows/open-pr.yml:46`
- Why: actions/checkout is pinned by the mutable tag v4 in the job that holds PR_TOKEN (also ci.yml, main.yml, scan.yml, actions/cache), so a moved tag runs foreign code beside the token
- Fix: pin every action by full commit hash with the tag in a comment
- Category: security
- Added: 2026-11-19
