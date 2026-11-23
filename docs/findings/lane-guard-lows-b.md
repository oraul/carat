## security Low: a fork's lone pull request can be recorded by wait

- Location: `tools/open_pr.sh`, the `wait` case, the recorded-number preference when several pull requests share the pushed head.
- Why it matters: with the read-back gone, `wait` can record a fork's lone pull request on the pushed head. The merger's step 1 returns `stale` for it, but the recorded-number preference then keeps the fork's number even after this repository's own pull request appears, so the run stalls until `pr` is cleared.
- Fix outline: drop the recorded preference when the merger returns `stale`, or clear `pr` on a stale result.
