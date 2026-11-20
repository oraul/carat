# Design

## Context

`open-pr.yml` runs from main on the completion of branch-push; its one job names the environment `AI` and its last step gives `PR_TOKEN` to `tools/open_pr.sh open`. The contributor's `open_pr.sh wait` sees pull requests only through `git ls-remote origin 'refs/pull/*/head'`, and the merger, which holds the GitHub read tool, merges the recorded number after checking its head commit.

## Decisions

- Same repository in `open`: `gh pr list --head BRANCH --state open --json number,isCrossRepository --jq '.[] | "\(.number) \(.isCrossRepository)"'` prints one line per open pull request; awk keeps the numbers whose flag is `false`. The script then names the pull request by number in `gh pr view` and `gh pr edit`, never by branch, since gh resolves a branch name to any pull request with that head name. After `gh pr create` the number is the last path segment of the address it prints, refused unless digits. The filter runs in the shell, not in gh's jq, so the tools-test stand-in exercises it.
- Environment rule: `rule` runs two reads, `repos/REPO/environments/AI` (`.deployment_branch_policy`, `null` when every branch may deploy) and `repos/REPO/environments/AI/deployment-branch-policies` (each policy as `TYPE NAME`, the type `branch` when absent). It passes only on `false true` (custom policies, not protected branches) and exactly the one line `branch main`, the setting pr-on-push asked for. A wider rule fails the job with a message naming the setting to apply. The step uses `github.token` with `actions: read`, which the environments endpoints accept, so no step but the open one holds `PR_TOKEN`. It runs before the read step, so a misconfiguration stops every run, not only those holding a pr.md. The check detects the setting; it cannot stop another branch's workflow while the setting is missing, which the message says.
- Merger: the one pull request read already returns the head's repository and branch; step 1 compares them with its input `repo` and `branch` beside the head commit. A mismatch returns `stale`, which the workflow treats as not merged and stops on. No guard change: the merge tool's hook sees no pull request data.
- Pin: `actions/checkout@11d5960a326750d5838078e36cf38b85af677262 # v4.4.0`, the commit `git ls-remote` showed for the tags `v4` and `v4.4.0`; the existing test counting one checkout with `persist-credentials: false` keeps matching.

## Risks

- If the repository's environment rule is set in another form (protected branches, or a pattern), open-pr fails on every push until the rule is set to the one branch `main`; the error names it. Reviewer guidance in the pull request notes says so.
- The jq filters run only on GitHub; they were checked with jq on sample responses of both endpoints and of `gh pr list`.
