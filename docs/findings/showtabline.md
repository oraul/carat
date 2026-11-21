### The package step's pull request text over-claims its own bookkeeping commits

- Location: the contributor's package mode (`.claude/agents/contributor.md`) and `tools/open_pr.sh` gate; comment-operator note 1, backlog-records-rule notes 1 and 5.
- Why: the text gate blocked round 1 and forced a second push in comment-operator (prtext 5,979 output, 16 calls, a bullet claiming its metrics row while history appended border-vocabulary's) and in backlog-records-rule (3 unasked cases claimed; prtext 8,118 output, 9 calls); pr_text_fixes 1 in 5 of the 12 newest run states against 11 of 286 overall.
- Fix: write Changes from the diff of the change's own files, leaving plan-apply and history commits out, and keep the contributor's cases to those the brief asks; accepted when the next five runs reaching a pull request record no pr-text-blocked note and pr_text_fixes stays 0.

### The merge phase costs more output than the check and security together

- Location: the merger start in `.claude/workflows/deliver-change.js`; comment-operator note 2.
- Why: merge 57,187 of 250,559 output (22.8 percent), 13 calls, ci_wait_calls 6, against check 9,886 and security 1,405; border-vocabulary 27.4 percent, listchars-folds 20.1, groom-evidence-only 16.7.
- Fix: wait for CI without an agent turn per poll; accepted when the merge phase stays under 10 percent of a run's output in each of the next five metrics rows, ci_wait_calls not higher, the merge still at the run state's squash commit.

### Scout pack reuse and pruning never changed a decision

- Location: the scout phase in `.claude/workflows/deliver-change.js` and `tmp/scout/`; comment-operator note 3.
- Why: scout 43,172 output, 42 calls (17.2 and 21.3 percent) for 3 areas, 0 of 3 packs reused, 0 pruned, while `tmp/scout` holds 398 packs (every configuration pack stale); border-vocabulary 45 scout calls, grep-long-files 39, listchars-folds 39.
- Fix: remove the reuse step or make it reuse; accepted when the next five scouted runs average under 8 scout calls per area or record a reused pack, and `tmp/scout` holds no pack the reuse check would reject.
