### ci, main, and scan workflows pin their actions by tag
- Location: `.github/workflows/ci.yml` (`actions/checkout@v4`, `actions/cache@v4`), `.github/workflows/main.yml` (the same), `.github/workflows/scan.yml` (`actions/checkout@v4`)
- Why: review-trust-lows-b pinned only open-pr, the job holding PR_TOKEN; a moved tag still runs in the other jobs, which hold the cache and the scan's verdict, though no token beyond GITHUB_TOKEN.
- Fix: pin each by the commit its tag names (`git ls-remote` of the action's repository), the tag in a comment, and extend the open-pr pin test of `tools/tools_test.sh` to every workflow.
### A fork's pull request on the pushed commit still delays a first push's wait
- Location: `tools/open_pr.sh` `wait` (the several-numbers refusal)
- Why: git shows no head repository, so a fork that opens a pull request on the pushed commit before the run state records a number makes the wait refuse; the merger now refuses a fork's pull request, but the delivery stops until the number is set by hand.
- Fix: have the open-pr workflow publish the number it opened or edited where git can read it (for example a check run name on the head the wait reads through the merger), or let the merger resolve the number from the branch with the GitHub read tool.
