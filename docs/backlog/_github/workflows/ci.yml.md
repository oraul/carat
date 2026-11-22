# Backlog: .github/workflows/ci.yml

## CI actions are pinned by tag

- Where: `.github/workflows/ci.yml` (line 36 `actions/checkout@v4`, and the same at lines 65, 91, 175, and 192, with `actions/cache@v4` and its `restore` and `save` forms). Low finding of the periodic security review at 66fd52b; at eb63fb4 the periodic security review found line 24 too, Low (3). Raised again at bff9a02 (#96): periodic security Low (6) at `.github/workflows/ci.yml:36`; queue item `ci-hardening`.
- Why it matters: a tag can be moved to other code, so a compromised action release would run in CI with the repository's token.
- Fix outline: pin each action to a full commit hash with the tag in a comment, and say in `CLAUDE.md` or the Makefile note how the pins are bumped.
- Also: CLAUDE.md, Makefile
- Category: security
- Added: 2026-11-03

## The CI checkout keeps the job token for every later step

- Where: `.github/workflows/ci.yml` line 36, `actions/checkout`. Periodic security Low (4) at 8d8832f, queued in `ci-hardening`.
- Why it matters: every later step runs the pull request's own Makefile and scripts with the read-only token in `.git/config`.
- Fix outline: set `persist-credentials: false`, since `tools/ci_scope.sh` uses the token through `gh`.
- Also: Makefile, tools/ci_scope.sh
- Category: security
- Added: 2026-11-10

## delivery-speed quality advisory at .github/workflows/ci.yml:26

- Where: `.github/workflows/ci.yml:26`. Delivery review of `delivery-speed` (quality advisory) at 2dcfd3d.
- Why it matters: the comment says every other stage runs only here, but docs-lint, dev-build, test-build, test-run, bench-budget, and metrics run in the checker too, and the line was left unwrapped.
- Fix outline: say CI runs every stage but diagnose and gates, rewrapped.
- Category: pipeline
- Added: 2026-11-11

### CI checkout keeps GITHUB_TOKEN while pull request targets run

- Location: .github/workflows/ci.yml:36 (sweep, security Low (6)).
- Why: the checkout keeps GITHUB_TOKEN in .git/config while the pull request's own make targets run.
- Fix outline: persist-credentials: false on the checkout; the scope step already reads through GH_TOKEN.
- Category: security
- Added: 2026-11-17

### Checkout keeps the default persist-credentials, leaving the read-only (sprint-20 sweep security Low (3), ci.yml:36)

- Location: `.github/workflows/ci.yml:36`
- Why: checkout keeps the default persist-credentials, leaving the read-only GITHUB_TOKEN in .git/config while later steps run the pull request's code (main.yml:34 likewise)
- Fix: set persist-credentials: false, the scope step already gets GH_TOKEN through env
- Category: security
- Added: 2026-11-19

### ci, main, and scan workflows pin their actions by tag
- Location: `.github/workflows/ci.yml` (`actions/checkout@v4`, `actions/cache@v4`), `.github/workflows/main.yml` (the same), `.github/workflows/scan.yml` (`actions/checkout@v4`)
- Why: review-trust-lows-b pinned only open-pr, the job holding PR_TOKEN; a moved tag still runs in the other jobs, which hold the cache and the scan's verdict, though no token beyond GITHUB_TOKEN.
- Fix: pin each by the commit its tag names (`git ls-remote` of the action's repository), the tag in a comment, and extend the open-pr pin test of `tools/tools_test.sh` to every workflow.
- Also: .github/workflows/main.yml, .github/workflows/scan.yml, tools/tools_test.sh
- Category: pipeline
- Added: 2026-11-21

### actions/checkout keeps the job token in .git/config (persist-credentials default) at .github/workflows/ci.yml:36 (sprint-26 sweep security Low (3), note 19)

- Location: .github/workflows/ci.yml:36
- Why: actions/checkout keeps the job token in .git/config (persist-credentials default) while make runs the pull request's code; the token is read-only, but nothing needs it after checkout
- Fix: set persist-credentials: false on the checkout step
- Category: security
- Added: 2026-11-22

### The CI checkout keeps the job token in .git/config at .github/workflows/ci.yml:36 (sprint-28 sweep security Low (4), note 19)

- Location: .github/workflows/ci.yml:36
- Why: the default persist-credentials stores the token (contents, pull-requests, checks read) where the pull request's Makefile and code run.
- Fix: persist-credentials false; the scope step already passes GH_TOKEN through env.
- Also: Makefile
- Category: security
- Added: 2026-11-22
