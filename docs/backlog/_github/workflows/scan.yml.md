# Backlog: .github/workflows/scan.yml

## A pull request can still run its own scan workflow

- Where: `.github/workflows/scan.yml:21` and the README's description of the pull request scan. Security Low (4) of the `remove-commit-hooks` review, raised again as Low (7) after its package step.
- Why it matters: a `pull_request` run uses the pull request's own workflow file, so a pull request that edits `scan.yml` back to `sh tools/pr_scan.sh` runs its own, possibly weakened, scanner and passes, contrary to the claim that a pull request cannot weaken its own check; the comment's promise holds for edits to `tools/*.sh` only. Not a regression: before that change the check was wholly under the pull request's control.
- Fix outline: have the merge gate (`tools/gates.sh` pre-merge, its content check) run the scanner from `origin/main`, copied with `git show origin/main:tools/scan_text.sh` into a temporary directory, or have the merger refuse a pull request that changes `.github/workflows/scan.yml`, `tools/scan_text.sh`, `tools/rules.sh`, or `tools/pr_scan.sh` without explicit review, with a `tools/tools_test.sh` case; either way narrow the `scan.yml` comment and the README to what the base checkout guarantees.
- Also: tools/pr_scan.sh, tools/gates.sh, tools/scan_text.sh, tools/rules.sh, tools/tools_test.sh
- Category: security
- Added: 2026-11-11

### A pull request's own scan.yml runs its scan

- Location: .github/workflows/scan.yml:13 (sprint-8 sweep, security Low (7)); queued in `ci-hardening`.
- Why: the pull_request event runs the pull request's copy of scan.yml, so a pull request editing it passes its own scan despite the base scanner.
- Fix: run the scan from the base's workflow reading the head only as data, or have the merge gate refuse a scan.yml change without the user's approval.
- Category: security
- Added: 2026-11-16
