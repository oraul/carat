## security Low: a fork's lone pull request can be recorded by wait

- Location: `tools/open_pr.sh`, the `wait` case, the recorded-number preference when several pull requests share the pushed head.
- Why it matters: with the read-back gone, `wait` can record a fork's lone pull request on the pushed head. The merger's step 1 returns `stale` for it, but the recorded-number preference then keeps the fork's number even after this repository's own pull request appears, so the run stalls until `pr` is cleared.
- Fix outline: drop the recorded preference when the merger returns `stale`, or clear `pr` on a stale result.

### The merge hook does not check the pull request number or the commit title
- Location: tools/agent_guard.sh merge_tool (the merge hook), beside tools/open_pr.sh wait
- Why: wait records a lone pull request on the pushed head without a scripted check of its head repository, so a fork's pull request on the same commit could be recorded and, if the merger skipped its step 1, squash-merged with the fork's own title as the commit subject; merge_tool checks expectedHeadSha, gated, and commit_message but not pullNumber or commit_title.
- Fix: in merge_tool, which needs no gh, refuse a merge whose pullNumber is not the run state's pr and one whose commit_title is not the archived pr.md title followed by a space and the number in parentheses, with a tools-test case each; separately clear pr in the run state when the merger returns stale.
